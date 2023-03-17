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
import "phoenix_html"

// Initialize variables for tracking ui state
let first_move = false;
let turn_color = 'white';

// Connect to the game websocket
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

  turn_color = payload.side_to_move;
  
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

    if (first_move === false) {
      first_move = true;
      updateClock();
    } else {
      opponent_clock.increment_by_setting();
    }
  }

  ground.playPremove();
});

//
// Clock Functionality
//

class Clock {
  constructor(element, time_control, inc) {
    this.element = element;
    this.time_control = time_control;
    this.inc = inc;
    this.minutes = time_control;
    this.seconds = 0;
    this.tenths = 0;

    this.element.innerHTML = this.time_as_string();
  }

  time_as_string() {
    let minutes = this.minutes;
    let seconds = this.seconds;
    let tenths = this.tenths;

    if (minutes < 10) {
      minutes = "0" + minutes;
    }
    if (seconds < 10) {
      seconds = "0" + seconds;
    }

    return minutes + ":" + seconds + "." + tenths;
  }

  decrement_by_tenth() {
    if (this.tenths === 0 && this.seconds > 0) {
      this.tenths = 9;
      this.seconds = this.seconds - 1;
    } else if (this.tenths > 0) {
      this.tenths = this.tenths - 1;
    } else if (this.seconds === 0 && this.tenths ==0 && this.minutes > 0) {
      this.seconds = 59;
      this.tenths = 9;
      this.minutes = this.minutes - 1;
    } else if (this.seconds === 0 && this.minutes === 0 && this.tenths === 0) {
    }
    this.element.innerHTML = this.time_as_string();
  }

  increment_by_setting() {
    this.seconds = this.seconds + this.inc;
    if (this.seconds >= 60) {
      this.minutes = this.minutes + 1;
      this.seconds = this.seconds - 60;
    }
    this.element.innerHTML = this.time_as_string();
  }
}

let clock = new Clock(document.getElementById('clock'), parseInt(time_control), parseInt(increment));
let opponent_clock = new Clock(document.getElementById('opponent_clock'), parseInt(time_control), parseInt(increment));

function updateClock() {
  if (turn_color === color) {
    clock.decrement_by_tenth();
  } else {
    opponent_clock.decrement_by_tenth();
  }
  setTimeout(updateClock, 100);
}

//
// Chat Update and Event Handlers
//

channel.on('shout', function (payload) { // listen to the 'shout' event
  let li = document.createElement("li"); // create new list item DOM element
  let name = payload.name || 'guest';    // get name from payload or set default
  li.innerHTML = '<b>' + name + '</b>: ' + payload.message; // set li contents
  ul.appendChild(li);                    // append to list
  scrollToBottom();
});

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

// Chessground config and event handlers

import { Chessground } from 'chessground';

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

