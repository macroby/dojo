// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../node_modules/chessground/assets/chessground.base.css"
import "../node_modules/chessground/assets/chessground.brown.css"
import "../node_modules/chessground/assets/chessground.cburnett.css"
import "../css/phoenix.css"
import "../css/app.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
import socket from "./socket"
import Clock from "./clock"
import { Chessground } from 'chessground';
import "phoenix_html"

//
// Initialize UI State
//
let clock = new Clock(document.getElementById('clock'), parseInt(time_control), parseInt(increment));
let opponent_clock = new Clock(document.getElementById('opponent_clock'), parseInt(time_control), parseInt(increment));

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
if (fen_turn === 1) {
  first_move = false;
} else {
  first_move = true;
  startClock();
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

channel.on('move', function (payload) {
  // Store the new fen in local storage.
  // This is used to restore the board state when the tab is duplicated.
  localStorage.setItem(window.location.pathname, payload.fen);

  let orig = payload.move.substring(0, 2);
  let dest = payload.move.substring(2, 4);
  ground.move(orig, dest);

  side_to_play = payload.side_to_move;
  
  // Check if this our own move and that it isnt our first move.
  // If it is, increment our own clock.
  if (payload.side_to_move !== color && first_move === true) {
    clock.increment_by_setting();
  }

  let new_dests = new Map(Object.entries(JSON.parse(JSON.parse(JSON.stringify(payload.dests)))))
  
  if (payload.side_to_move === color) {
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
    } else {
      opponent_clock.increment_by_setting();
    }
  }

  ground.playPremove();
});

channel.on('shout', function (payload) { // listen to the 'shout' event
  let li = document.createElement("li"); // create new list item DOM element
  let name = payload.name || 'guest';    // get name from payload or set default
  li.innerHTML = '<b>' + name + '</b>: ' + payload.message; // set li contents
  ul.appendChild(li);                    // append to list
  scrollToBottom();
});

//
// Clock UI Config and Timekeeping Functionality
//

// Start the clock. This is called after the first move is made.
// Only purpose is to denote in a clear way that the clock has started,
// otherwise updateClock() would be called directly.
function startClock() {
  updateClock();
}

// Every 100ms, update the clock.
function updateClock() {
  if (side_to_play === color) {
    clock.decrement_by_tenth();
  } else {
    opponent_clock.decrement_by_tenth();
  }
  setTimeout(updateClock, 100);
}

//
// Chat Update and Client-Side Event Handlers
//

let ul = document.getElementById('msg-list');        // list of messages.
let name = document.getElementById('name');          // name of message sender
let msg = document.getElementById('msg');            // message input field

// "listen" for the [Enter] keypress event to send a message:
msg.addEventListener('keypress', function (event) {
  if (event.keyCode == 13 && msg.value.length > 0) { // don't sent empty msg.
    channel.push('shout', { // send the message to the server on "shout" channel
      name: sanitise(name.value) || "guest",     // get value of "name" of person sending the message
      message: sanitise(msg.value)    // get message text (value) from msg input field.
    });
    msg.value = '';         // reset the message input field for next message.
  }
});

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

const dests_map = new Map(Object.entries(JSON.parse(JSON.parse(JSON.stringify(dests)))));

const config = {
  fen: fen,
  orientation: color,
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

export function playOtherSide() {
  
  return (orig, dest) => {
    channel.push('move', { 
      move: sanitise(orig).concat(sanitise(dest))
    });
  };
}

