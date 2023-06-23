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
import PromotionPrompt from "./promotion_prompt"
import ResignButton from "./resign_button"
import { main } from "./result.bs"
import { Chessground } from 'chessground';
import "phoenix_html"

//
// Initialize UI State
//
let clock;
let opponent_clock;
if (color === 'white') {
  clock = new Clock(document.getElementById('clock'), white_clock, parseInt(increment));
  opponent_clock = new Clock(document.getElementById('opponent_clock'), black_clock, parseInt(increment));
} else {
  clock = new Clock(document.getElementById('clock'), black_clock, parseInt(increment));
  opponent_clock = new Clock(document.getElementById('opponent_clock'), white_clock, parseInt(increment));
}
let promotion_prompt = new PromotionPrompt(document.getElementById('promotion_prompt'));
let resign_button = new ResignButton(document.getElementById('resign'));

var result_tea = main(document.getElementById("result"));

let fen_array = fen.split(' ');
let fen_side_to_play = fen_array[1];
let fen_turn = parseInt(fen_array[fen_array.length - 1]);
let side_to_play;
if (fen_side_to_play === 'w') {
  side_to_play = 'white';
} else {
  side_to_play = 'black';
}
let first_move;
if (game_status !== 'continue') {
  result_tea.pushMsg({msg: "SetResult", _0: game_status});
  result_tea.pushMsg(0);
} else {
  if (fen_turn === 1) {
    first_move = false;
  } else {
    first_move = true;
    startClock();
  }
}

let promotion_dests = get_promotions_from_dests(dests);

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

//
// Connect to the game websocket
//

var roomID = window.location.pathname;
let channel = socket.channel('room:' + roomID.replace('/', ''), {}); // connect to chess "room"
channel.join(); // join the channel.

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

  result_tea.pushMsg({msg: "SetResult", _0: payload.winner});
  result_tea.pushMsg(0);
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
  movable: {events: {after: playOtherSide()}}
});

if (game_status !== 'continue') {
  ground.stop();
}

export function playOtherSide() {
  return (orig, dest) => {
    let move = sanitise(orig).concat(sanitise(dest));
    let is_promotion_move = false;

    for (let i = 0; i < promotion_dests.length; i++) {
      if (promotion_dests[i][0] === orig && promotion_dests[i][1] === dest) {
        is_promotion_move = true;
        promotion_prompt.set_orig_dest(orig, dest);
        promotion_prompt.reveal();
        break;
      }
    }

    if (is_promotion_move === false) {
      channel.push('move', { 
        move: move,
      });
    }
  };
}

//
// Promotion Piece Selection UI
//

promotion_prompt.onclick(function (orig, dest, piece) {
  promotion_prompt.hide();
  if (piece === 'c') {
    ground.set({
      fen: fen,
      turnColor: color,
      movable: {
        color: color,
        dests: dests_map
      }
    });
  } else {
    channel.push('move', { 
      move: sanitise(orig).concat(sanitise(dest)).concat(sanitise(piece)),
    });
  }
});

//
// Resign Button
//

resign_button.onClick(function () {
  channel.push('resign', {});
});
