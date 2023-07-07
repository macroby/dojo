%%raw(`
// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../node_modules/chessground/assets/chessground.base.css"
import "../node_modules/chessground/assets/chessground.brown.css"
import "../node_modules/chessground/assets/chessground.cburnett.css"
import "../css/app.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
// import socket from "./room_socket"
import { Chessground } from 'chessground';
import {Socket} from "phoenix";
import "phoenix_html"
`)

//
// Initialize UI State
//

@scope("document") external getElementById: string => Js.null_undefined<Dom.node> = "getElementById"

let color_res: string = %raw(`color`)
let white_clock_res: int = %raw(`white_clock`)
let black_clock_res: int = %raw(`black_clock`)
let timeControl: string = %raw(`time_control`)
let halfmove_clock_res: int = %raw(`halfmove_clock`)

let fen_array: array<string> = %raw(`fen.split(' ')`)
let fen_side_to_play: string = fen_array[1]
let fen_array_length = Js.Array.length(fen_array)
let fen_turn: int = int_of_string(fen_array[fen_array_length - 1])
let side_to_play = switch fen_side_to_play {
| "w" => "white"
| "b" => "black"
| _ => failwith("Invalid side to play")
}

%%raw(`
//
// Chessground config and Client-Side event handlers
//

dests_map = new Map(Object.entries(dests));
const config = {
  fen: fen,
  orientation: color,
  turnColor: side_to_play,
  movable: {
    color: color,
    free: false,
    dests: dests_map
  }
};

var ground = Chessground(document.getElementById('chessground'), config);

ground.set({
  movable: {events: {after: playOtherSide}}
});

if (game_status !== 'continue') {
  ground.stop();
}
`)

let gameStatus: string = %raw(`game_status`)

let promotion_dests = %raw(`get_promotions_from_dests(dests)`)

%%raw(`
function get_promotions_from_dests(dests) {
  let promotion_dests = [];
  for (const [key, value] of Object.entries(dests)) {
    let unique_square = value.filter((v, i) => value.indexOf(v) !== i);
    if (unique_square.length !== 0) {
      unique_square = value.filter((v, i) => value.indexOf(v) === i);
      for (let i = 0; i < unique_square.length; i++) {
        promotion_dests.push([key, unique_square[i]]);
      }
    }
  }
  return promotion_dests;
}
`)

let user_token_res: string = %raw(`user_token`)

let socket = Phoenix.newSocket("/room_socket", {token: user_token_res})

Phoenix.connect(socket)

let roomID = %raw(`window.location.pathname`)
let channel = Phoenix.newChannel(socket, "room:" ++ Js.String.replace("/", "", roomID), {})
Phoenix.joinChannel(channel)

let roomTea = RoomTea.main(getElementById("room-tea"))()

roomTea["pushMsg"](
  Initialize(
    %raw("fen"),
    %raw("dests"),
    %raw("color"),
    %raw("game_type"),
    %raw("invite_accepted"),
    %raw("increment"),
    %raw("white_clock"),
    %raw("black_clock"),
    %raw("game_status"),
    %raw("user_token"),
    %raw("time_control"),
    side_to_play,
    %raw("ground"),
    %raw("channel"),
  ),
)

// Phoenix.on(channel, "start_ping", payload => {
//   Phoenix.push(channel, "ping")
// })

// TODO: get ping pong working again
// Phoenix.on(channel, "pong", payload => {
//   Js.Global.setTimeout(() => Phoenix.push(channel, "ping", %raw(`{}`)), 2500)
// })

Phoenix.on(channel, "ack", payload => {
  ()
})

Phoenix.on(channel, "endData", payload => {
  %raw(`ground.set({viewOnly: true})`)->ignore
  %raw(`ground.stop()`)->ignore

  roomTea["pushMsg"](StopClock)
  roomTea["pushMsg"](ShowResult(payload["winner"]))
})

Phoenix.on(channel, "move", payload => {
  let halfmove_clock = payload["halfmove_clock"]
  %raw(`clientStateJson = localStorage.getItem(window.location.pathname)`)
  %raw(`clientStateObject = JSON.parse(clientStateJson)`)
  %raw(`clientStateObject.fen = payload.fen`)
  %raw(`localStorage.setItem(window.location.pathname, JSON.stringify(clientStateObject))`)
  %raw(`fen = payload.fen`)
  let orig = %raw(`payload.move.substring(0, 2)`)
  let dest = %raw(`payload.move.substring(2, 4)`)
  Js.log(orig) //trick the compiler
  Js.log(dest)
  %raw(`ground.move(orig, dest)`)->ignore
  %raw(`ground.set({fen: payload.fen})`)->ignore

  %raw(`side_to_play = payload.side_to_move`)
  switch %raw(`color`) {
  | "white" =>
    roomTea["pushMsg"](UpdateClocksWithServerTime(payload["white_clock"], payload["black_clock"]))
  | "black" =>
    roomTea["pushMsg"](UpdateClocksWithServerTime(payload["black_clock"], payload["white_clock"]))
  | _ => failwith("Invalid side to play")
  }
  switch %raw(`payload.side_to_move`) === %raw(`color`) {
  | true => {
      let new_dests = %raw(`new Map(Object.entries(payload.dests))`)
      let promotion_dests = %raw(`get_promotions_from_dests(payload.dests)`)
      Js.log(new_dests)
      Js.log(promotion_dests)

      %raw(`ground.set({turnColor: payload.side_to_move, movable: {color: payload.side_to_move, dests: new_dests}})`)
    }
  | false => ()
  }
  switch halfmove_clock == 2 {
  | true => %raw(`startClock()`)
  | false => ()
  }
  %raw(`ground.playPremove()`)
})

//
// Clock UI Config and Timekeeping Functionality
//

@val external setTimeout: (int => unit, int, int) => unit = "setTimeout"

// Update clock UI. Accounts for drift and ensures that the clock is
// updated at the correct interval. Accounts for idle tab messing with
// the setInterval() function.
let rec updateClock = expected => {
  let color_res = %raw(`color`)
  let side_to_play_res = %raw(`side_to_play`)
  let interval = 50
  let new_expected = expected + interval
  let dt = Belt.Float.toInt(Js.Date.now()) - expected // the drift (positive for overshooting)

  switch dt > interval {
  | true => {
      // something really bad happened. Maybe the browser (tab) was inactive?
      // possibly special handling to avoid futile "catch up" run
      if side_to_play === color_res {
        roomTea["pushMsg"](DecrementUserTime(dt))
      } else {
        roomTea["pushMsg"](DecrementOpponentTime(dt))
      }

      let new_expected = Belt.Float.toInt(Js.Date.now()) + interval
      let dt = mod(dt, interval)

      setTimeout(updateClock, Js.Math.max_int(0, interval), new_expected)
    }
  | false => {
      if side_to_play_res === color_res {
        roomTea["pushMsg"](DecrementUserTime(interval))
      } else {
        roomTea["pushMsg"](DecrementOpponentTime(interval))
      }

      setTimeout(updateClock, Js.Math.max_int(0, interval - dt), new_expected)
    }
  }
}

let startClock = () => {
  // I dont know how to get the compiler to keep these declarations but
  // I am keeping them here for now for reference
  let interval = 50
  let expected = %raw(`Date.now()`) + 50
  interval->ignore
  expected->ignore
  %raw(`setTimeout(updateClock, 50, Date.now() + 50)`)
}

switch halfmove_clock_res > 1 {
| true => %raw(`startClock()`)
| false => ()
}

%%raw(`
/**
 * sanitise input to avoid XSS see: https://git.io/fjpGZ
 * function borrowed from: https://stackoverflow.com/a/48226843/1148249
 * @param {string} str - the text to be sanitised.
 * @return {string} str - the santised text
 */
function sanitise(str) {
  const map = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#x27;',
      "/": '&#x2F;',
  };
  const reg = /[&<>"'/]/ig;
  return str.replace(reg, (match)=>(map[match]));
}
`)

let playOtherSide = (orig: string, dest: string) => {
  let move: string = %raw(`sanitise(orig).concat(sanitise(dest))`)
  Js.log(move) // hack to get the compiler to keep move in js output
  let is_promotion_move = ref(false)

  Js.Array.forEach(promotion_dest => {
    is_promotion_move.contents = switch promotion_dest == (orig, dest) {
    | true => {
        roomTea["pushMsg"](ShowPromotionPrompt(orig, dest))
        true
      }
    | false => is_promotion_move.contents
    }
  }, promotion_dests)
  switch is_promotion_move.contents {
  | true => ()
  | false =>
    %raw(`
        channel.push('move', { 
          move: move,
        })
      `)
  }
}
