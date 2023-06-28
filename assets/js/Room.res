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

let result = Result.main(getElementById("result"))(())
let promotionPrompt = PromotionPrompt.main(getElementById("promotion_prompt"))(())
let resignButton = ResignButton.main(getElementById("resign"))(())

let color_res: string = %raw(`color`)
let white_clock_res: int = %raw(`white_clock`)
let black_clock_res: int = %raw(`black_clock`)
let timeControl: string = %raw(`time_control`)

let (clock, opponentClock) = (Clock.main(getElementById("clock"))(()), Clock.main(getElementById("opponent_clock"))(()))

switch color_res {
  | "white" => 
    clock["pushMsg"](SetTimeAsMilli(white_clock_res))
    opponentClock["pushMsg"](SetTimeAsMilli(black_clock_res))
  | "black" => 
    clock["pushMsg"](SetTimeAsMilli(black_clock_res))
    opponentClock["pushMsg"](SetTimeAsMilli(white_clock_res))  
  | _ => failwith("Invalid color")
}

switch timeControl {
  | "real_time" => ()
  | _ => {
    clock["pushMsg"](Hide)
    clock["pushMsg"](Stop)
    opponentClock["pushMsg"](Hide)
    opponentClock["pushMsg"](Stop)
  }
}

let fen_array: array<string> = %raw(`fen.split(' ')`)
let fen_side_to_play: string = fen_array[1]
let fen_array_length = Js.Array.length(fen_array)
let fen_turn: int = int_of_string(fen_array[fen_array_length - 1])
let side_to_play = switch fen_side_to_play {
  | "w" => "white"
  | "b" => "black"
  | _ => failwith("Invalid side to play")
}

let gameStatus: string = %raw(`game_status`)
let first_move = switch gameStatus {
  | "continue" => switch fen_turn {
    | 1 => false
    | _ => {
        %raw(`startClock()`) -> ignore
        true
      }
  }
  | _ => {
    result["pushMsg"](Result.SetResult(gameStatus))
    result["pushMsg"](Result.ShowResult)
    false
  }
}

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

module Phoenix = {
  type socket = Socket
  type channel = Channel
  type params = {token: string}
  type chanParams = {}
  type endPoint = string

  let newSocket = (endPoint: endPoint, params: params) => {
    %raw(`new Socket(endPoint, {params: params})`)
  }

  let connect = (socket: socket) => {
    %raw(`socket.connect()`)
  }

  let newChannel = (socket: socket, topic: string, params: chanParams) => {
    %raw(`socket.channel(topic, params)`)
  }

  let joinChannel = (channel: channel) => {
    %raw(`channel.join()`)
  }


  let on = (channel: channel, message: string, callback: 'a) => {
    %raw(`channel.on(message, callback)`)
  }

  let push = (channel: channel, message: string) => {
    %raw(`channel.push(message, {})`)
  }
}

let user_token_res: string = %raw(`user_token`)

let socket = Phoenix.newSocket("/room_socket", {token: user_token_res})

Phoenix.connect(socket)

let roomID = %raw(`window.location.pathname`)
let channel = Phoenix.newChannel(socket, "room:" ++ Js.String.replace("/", "", roomID), {})
Phoenix.joinChannel(channel)

Phoenix.on(channel, "start_ping", payload => {
  Phoenix.push(channel, "ping")
})

Phoenix.on(channel, "pong", payload => {
  Js.Global.setTimeout(() => Phoenix.push(channel, "ping"), 2500)
})

Phoenix.on(channel, "ack", payload => {
  ()
})

Phoenix.on(channel, "endData", payload => {
  %raw(`ground.set({viewOnly: true})`) -> ignore
  %raw(`ground.stop()`) -> ignore
  clock["pushMsg"](Stop)
  opponentClock["pushMsg"](Stop)
  result["pushMsg"](Result.SetResult(payload["winner"]))
  result["pushMsg"](Result.ShowResult)
})

Phoenix.on(channel, "move", payload => {
  %raw(`clientStateJson = localStorage.getItem(window.location.pathname)`)
  %raw(`clientStateObject = JSON.parse(clientStateJson)`)
  %raw(`clientStateObject.fen = payload.fen`)
  %raw(`localStorage.setItem(window.location.pathname, JSON.stringify(clientStateObject))`)
  let orig = %raw(`payload.move.substring(0, 2)`)
  let dest = %raw(`payload.move.substring(2, 4)`)
  Js.log(orig) //trick the compiler
  Js.log(dest)
  %raw(`ground.move(orig, dest)`) -> ignore
  %raw(`ground.set({fen: payload.fen})`) -> ignore

  %raw(`side_to_play = payload.side_to_move`)
  switch %raw(`color`) {
    | "white" => {
      clock["pushMsg"](SetTimeAsMilli(payload["white_clock"]))
      opponentClock["pushMsg"](SetTimeAsMilli(payload["black_clock"]))
    }
    | "black" => {
      clock["pushMsg"](SetTimeAsMilli(payload["black_clock"]))
      opponentClock["pushMsg"](SetTimeAsMilli(payload["white_clock"]))
    }
    | _ => failwith("Invalid side to play")
  }
  switch %raw(`payload.side_to_move`) === %raw(`color`) {
    | true => {

      let new_dests = %raw(`new Map(Object.entries(payload.dests))`)
      let promotion_dests = %raw(`get_promotions_from_dests(payload.dests)`)
      Js.log(new_dests)
      Js.log(promotion_dests)

      %raw(`ground.set({turnColor: payload.side_to_move, movable: {color: payload.side_to_move, dests: new_dests}})`)
      switch %raw(`first_move`) {
        | false => {
          %raw(`first_move = true`)
          %raw(`startClock()`)
        }
        | true => {
          ()
        }
      }
    }
    | false => {
        ()
    }
  }
  %raw(`ground.playPremove()`)
})

%%raw(`
// channel.on('shout', function (payload) { // listen to the 'shout' event
//   let li = document.createElement("li"); // create new list item DOM element
//   let name = payload.name || 'guest';    // get name from payload or set default
//   li.innerHTML = '<b>' + name + '</b>: ' + payload.message; // set li contents
//   ul.appendChild(li);                    // append to list
//   scrollToBottom();
// });
`)

//
// Clock UI Config and Timekeeping Functionality
//

@val external setTimeout: (int => unit, int, int) => unit = "setTimeout"

// Update clock UI. Accounts for drift and ensures that the clock is
// updated at the correct interval. Accounts for idle tab messing with
// the setInterval() function.
let rec updateClock = (expected) => {
  let color_res = %raw(`color`)
  let side_to_play_res = %raw(`side_to_play`)
  let interval = 50
  let new_expected = expected + interval
  let dt = Belt.Float.toInt(Js.Date.now()) - expected // the drift (positive for overshooting)


  switch dt > interval {
    | true => {
      // something really bad happened. Maybe the browser (tab) was inactive?
      // possibly special handling to avoid futile "catch up" run
      if (side_to_play === color_res) {
        clock["pushMsg"](DecrementTimeAsMilli(dt))
      } else {
        opponentClock["pushMsg"](DecrementTimeAsMilli(dt))
      }

      let new_expected = Belt.Float.toInt(Js.Date.now()) + interval
      let dt = mod(dt, interval)

      setTimeout(updateClock, Js.Math.max_int(0, interval), new_expected)
    }
    | false => {
      if (side_to_play_res === color_res) {
        clock["pushMsg"](DecrementTimeAsMilli(interval))
      } else {
        opponentClock["pushMsg"](DecrementTimeAsMilli(interval))
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
  interval -> ignore
  expected -> ignore
  %raw(`setTimeout(updateClock, 50, Date.now() + 50)`)
}

// %%raw(`
// //
// // Chat Update and Client-Side Event Handlers
// //

// // let ul = document.getElementById('msg-list');        // list of messages.
// // let name = document.getElementById('name');          // name of message sender
// // let msg = document.getElementById('msg');            // message input field

// // // "listen" for the [Enter] keypress event to send a message:
// // msg.addEventListener('keypress', function (event) {
// //   if (event.keyCode == 13 && msg.value.length > 0) { // don't sent empty msg.
// //     channel.push('shout', { // send the message to the server on "shout" channel
// //       name: sanitise(name.value) || "guest",     // get value of "name" of person sending the message
// //       message: sanitise(msg.value)    // get message text (value) from msg input field.
// //     });
// //     msg.value = '';         // reset the message input field for next message.
// //   }
// // });

// // // see: https://stackoverflow.com/a/33193668/1148249
// // let scrollingElement = (document.scrollingElement || document.body)
// // function scrollToBottom () {
// //   scrollingElement.scrollTop = scrollingElement.scrollHeight;
// // }
// `)

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

const ground = Chessground(document.getElementById('chessground'), config);

ground.set({
  movable: {events: {after: playOtherSide}}
});

if (game_status !== 'continue') {
  ground.stop();
}
`)

let playOtherSide = (orig: string, dest: string) => {
  let move: string = %raw(`sanitise(orig).concat(sanitise(dest))`)
  Js.log(move)// hack to get the compiler to keep move in js output
  let is_promotion_move = ref(false);
  
  Js.Array.forEach(promotion_dest => {
      is_promotion_move.contents = switch (promotion_dest == (orig, dest)) {
        | true => {
          promotionPrompt["pushMsg"](SetOrigDest(orig, dest))
          promotionPrompt["pushMsg"](ShowPromotionPrompt)
          true
        }
        | false => is_promotion_move.contents
      };
    }, promotion_dests);
  switch (is_promotion_move.contents) {
    | true => {
      ()
    }
    | false => {
      %raw(`
        channel.push('move', { 
          move: move,
        })
      `)
    }
  }
}

//
// Promotion Piece Selection UI
//
let onclickFunction = (orig: option<string>, dest: option<string>, promoPromptOption: PromotionPrompt.promoPromptOption) => {
  let orig_unwrap = Belt.Option.getWithDefault(orig, "")
  let dest_unwrap = Belt.Option.getWithDefault(dest, "")

  // hack to force the compiler to keep orig_unwrap and dest_unwrap in the js output
  Js.log(orig_unwrap)
  Js.log(dest_unwrap)

  promotionPrompt["pushMsg"](HidePromotionPrompt)
  switch (promoPromptOption) {
    | Cancel => {
      %raw(`
        ground.set({
          fen: fen,
          turnColor: color,
          movable: {
            color: color,
            dests: dests_map
          }
        })
      `) -> ignore
      ()
    }
    | Queen => {
      %raw(`
        channel.push('move', { 
          move: sanitise(orig_unwrap).concat(sanitise(dest_unwrap)).concat(sanitise("q")),
        })
      `) -> ignore
      ()
    }
    | Rook => {
      %raw(`
        channel.push('move', { 
          move: sanitise(orig_unwrap).concat(sanitise(dest_unwrap)).concat(sanitise("r")),
        })
      `) -> ignore
      ()
    }
    | Bishop => {
      %raw(`
        channel.push('move', { 
          move: sanitise(orig_unwrap).concat(sanitise(dest_unwrap)).concat(sanitise("b")),
        })
      `) -> ignore
      ()
    }
    | Knight => {
      %raw(`
        channel.push('move', { 
          move: sanitise(orig_unwrap).concat(sanitise(dest_unwrap)).concat(sanitise("n")),
        })
      `) -> ignore
      ()
    }
  }
}
promotionPrompt["pushMsg"](SetOnClick(onclickFunction))

let resignOnClick = () => {
  %raw(`
    channel.push('resign', {})
  `) -> ignore
}

resignButton["pushMsg"](SetOnClick(resignOnClick))