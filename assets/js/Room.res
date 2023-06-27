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
import socket from "./room_socket"
import Clock from "./clock"
import { Chessground } from 'chessground';
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

let (clock, opponent_clock) = switch color_res {
  | "white" => (%raw(`new Clock(document.getElementById('clock'), white_clock, parseInt(increment))`), %raw(`new Clock(document.getElementById('opponent_clock'), black_clock, parseInt(increment))`))
  | "black" => (%raw(`new Clock(document.getElementById('clock'), black_clock, parseInt(increment))`), %raw(`new Clock(document.getElementById('opponent_clock'), white_clock, parseInt(increment))`))
  | _ => failwith("Invalid color")
}

// let (clockTea, opponentClockTea) = switch color_res {
//   | "white" => (ClockTea.main(getElementById("test1"))(()), ClockTea.main(getElementById("test2"))(()))
//   | "black" => (ClockTea.main(getElementById("test2"))(()), ClockTea.main(getElementById("test1"))(()))
//   | _ => failwith("Invalid color")
// }

// switch color_res {
//   | "white" => 
//     clockTea["pushMsg"](SetTimeAsMilli(white_clock_res))
//     opponentClockTea["pushMsg"](SetTimeAsMilli(black_clock_res))
//   | "black" => 
//     clockTea["pushMsg"](SetTimeAsMilli(black_clock_res))
//     opponentClockTea["pushMsg"](SetTimeAsMilli(white_clock_res))  
//   | _ => failwith("Invalid color")
// }

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

%%raw(`
//
// Connect to the game websocket
//

var roomID = window.location.pathname;
let channel = socket.channel('room:' + roomID.replace('/', ''), {}); // connect to chess "room"
channel.join(); // join the channel.
`)

%%raw(`
//
// Incoming events from server
//

channel.on('start_ping', function (payload) { // listen to the 'shout' event
  channel.push('ping', {});
});

channel.on('pong', function (payload) { // listen to the 'shout' event
  setTimeout(() => channel.push('ping', {}), 2500);
});

channel.on('ack', function (payload) {
})

channel.on('endData', function (payload) {
  // I set viewonly to true here because ground.stop() alone
  // doesn't seem to work properly for black client.
  ground.set({
    viewOnly: true
  });
  ground.stop();
  clock.stop();
  opponent_clock.stop();

  result.pushMsg({msg: "SetResult", _0: payload.winner});
  result.pushMsg(0);
})

channel.on('move', function (payload) {
  // Store the new fen in local storage.
  // This is used to restore the board state when the tab is duplicated.
  clientStateJson = localStorage.getItem(window.location.pathname);
  clientStateObject = JSON.parse(clientStateJson);
  clientStateObject.fen = payload.fen;
  localStorage.setItem(window.location.pathname, JSON.stringify(clientStateObject));

  let orig = payload.move.substring(0, 2);
  let dest = payload.move.substring(2, 4);
  ground.move(orig, dest);
  ground.set({
    fen: payload.fen
  });

  side_to_play = payload.side_to_move;
  if (color === 'white') {
    clock.set_time(payload.white_clock);
    opponent_clock.set_time(payload.black_clock);
  } else {
    clock.set_time(payload.black_clock);
    opponent_clock.set_time(payload.white_clock);
  }
  
  if (payload.side_to_move === color) {
    let new_dests = new Map(Object.entries(payload.dests));
    promotion_dests = get_promotions_from_dests(payload.dests);

    ground.set({
      turnColor: payload.side_to_move,
      movable: {
        color: payload.side_to_move,
        dests: new_dests
      }
    }); 

    // If the opponent has made their first move, start the clock.
    if (first_move === false) {
      first_move = true;
      startClock();
    }
  }

  ground.playPremove();
});

// channel.on('shout', function (payload) { // listen to the 'shout' event
//   let li = document.createElement("li"); // create new list item DOM element
//   let name = payload.name || 'guest';    // get name from payload or set default
//   li.innerHTML = '<b>' + name + '</b>: ' + payload.message; // set li contents
//   ul.appendChild(li);                    // append to list
//   scrollToBottom();
// });
`)

%%raw(`
//
// Clock UI Config and Timekeeping Functionality
//

// Start the clock. This is called after the first move is made.
// Initiates the clock with 50 ms update interval.
function startClock() {
  var interval = 50;
  var expected = Date.now() + interval;
  
  setTimeout(updateClock, interval, expected);
}

// Update clock UI. Accounts for drift and ensures that the clock is
// updated at the correct interval. Accounts for idle tab messing with
// the setInterval() function.
function updateClock(expected) {
  var interval = 50;
  var new_expected = expected + interval;
  var dt = Date.now() - expected; // the drift (positive for overshooting)
  if (dt > interval) {
    // something really bad happened. Maybe the browser (tab) was inactive?
    // possibly special handling to avoid futile "catch up" run

    if (side_to_play === color) {
      clock.decrement_time(dt);
    } else {
      opponent_clock.decrement_time(dt);
    }
    new_expected = Date.now() + interval;
    dt = dt % interval;

    setTimeout(updateClock, Math.max(0, interval), new_expected);
  } else {
    if (side_to_play === color) {
      clock.decrement_time(50);
    } else {
      opponent_clock.decrement_time(50);
    }
    setTimeout(updateClock, Math.max(0, interval - dt), new_expected);
  }
}
`)

%%raw(`
//
// Chat Update and Client-Side Event Handlers
//

// let ul = document.getElementById('msg-list');        // list of messages.
// let name = document.getElementById('name');          // name of message sender
// let msg = document.getElementById('msg');            // message input field

// // "listen" for the [Enter] keypress event to send a message:
// msg.addEventListener('keypress', function (event) {
//   if (event.keyCode == 13 && msg.value.length > 0) { // don't sent empty msg.
//     channel.push('shout', { // send the message to the server on "shout" channel
//       name: sanitise(name.value) || "guest",     // get value of "name" of person sending the message
//       message: sanitise(msg.value)    // get message text (value) from msg input field.
//     });
//     msg.value = '';         // reset the message input field for next message.
//   }
// });

// see: https://stackoverflow.com/a/33193668/1148249
let scrollingElement = (document.scrollingElement || document.body)
function scrollToBottom () {
  scrollingElement.scrollTop = scrollingElement.scrollHeight;
}
`)

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