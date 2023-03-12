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
  ping_with_delay();
});

async function ping_with_delay() {
  let promise = new Promise((resolve, reject) => {
    setTimeout(() => resolve("done waiting"), 2500)
  });

  let result = await promise;

  channel.push('ping', {});
}

channel.on('shout', function (payload) { // listen to the 'shout' event
  let li = document.createElement("li"); // create new list item DOM element
  let name = payload.name || 'guest';    // get name from payload or set default
  li.innerHTML = '<b>' + name + '</b>: ' + payload.message; // set li contents
  ul.appendChild(li);                    // append to list
  scrollToBottom();
});

channel.on('move', function (payload) {
  // Store the new fen in local storage.
  // This is used to restore the board state when the tab is duplicated.
  localStorage.setItem(window.location.pathname, payload.fen);

  let orig = payload.move.substring(0, 2);
  let dest = payload.move.substring(2, 4);
  ground.move(orig, dest);

  let new_dests = new Map(Object.entries(JSON.parse(JSON.parse(JSON.stringify(payload.dests)))))
  
  if (payload.side_to_move === color) {
    ground.set({
      turnColor: payload.side_to_move,
      movable: {
        color: payload.side_to_move,
        dests: new_dests
      }
    }); 
  }

  ground.playPremove();
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

