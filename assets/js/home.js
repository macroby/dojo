import "../css/phoenix.css"
import "../css/app.css"

import socket from "./home_socket"
import GameList from "./game_list"
//
import "phoenix_html"

let channel = socket.channel('home:lobby', {}); // connect to chess "room"

channel.on('shout', function (payload) { // listen to the 'shout' event
  let li = document.createElement("li"); // create new list item DOM element
  let name = payload.name || 'guest';    // get name from payload or set default
  li.innerHTML = '<b>' + name + '</b>: ' + payload.message; // set li contents
  ul.appendChild(li);                    // append to list
  scrollToBottom();
});

channel.join(); // join the channel.


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

// Get the modal
let createGameModal = document.getElementById("createGameModal");
let playWithFriendModal = document.getElementById("playWithFriendModal");
let playWithComputerModal = document.getElementById("playWithComputerModal")

// Get the button that opens the modal
let createGameBtn = document.getElementById("createGameBtn");
let playWithFriendBtn = document.getElementById("playWithFriendBtn");
let playWithComputerBtn = document.getElementById("playWithComputerBtn");

// Get the <span> element that closes the modal
let createGameSpan = document.getElementById("createGameClose");
let playWithFriendSpan = document.getElementById("playWithFriendClose");
let playWithComputerSpan = document.getElementById("playWithComputerClose");

// When the user clicks on the button, open the modal
createGameBtn.onclick = function() {
  createGameModal.style.display = "block";
}
playWithFriendBtn.onclick = function() {
  playWithFriendModal.style.display = "block";
}
playWithComputerBtn.onclick = function() {
  playWithComputerModal.style.display = "block";
}

// When the user clicks on <span> (x), close the modal
createGameSpan.onclick = function() {
  createGameModal.style.display = "none";
}
playWithFriendSpan.onclick = function() {
  playWithFriendModal.style.display = "none";
}
playWithComputerSpan.onclick = function() {
  playWithComputerModal.style.display = "none";
}
 
// When the user clicks anywhere outside of the modal, close it
window.onclick = function(event) {
  if (event.target == createGameModal) {
    createGameModal.style.display = "none";
  }
  if (event.target == playWithFriendModal) {
    playWithFriendModal.style.display = "none";
  }
  if (event.target == playWithComputerModal) {
    playWithComputerModal.style.display = "none";
  }
}

let timeControlSelectCreateGame = document.getElementById("time-control-select-create-game");
timeControlSelectCreateGame.onchange = function() {
  let timeControl = timeControlSelectCreateGame.value;
  let timeControlRealTimeInput = document.getElementById("time-control-real-time-create-game");
  let timeControlCorrespondenceInput = document.getElementById("time-control-correspondence-create-game");
  if (timeControl == "real time") {
    timeControlRealTimeInput.style.display = "block";
  } else if (timeControl == "correspondence") {
    timeControlCorrespondenceInput.style.display = "block";
  }
  else {
    timeControlRealTimeInput.style.display = "none";
    timeControlCorrespondenceInput.style.display = "none";
  }
}

let timeControlSelectWithFriend = document.getElementById("time-control-select-with-friend");
timeControlSelectWithFriend.onchange = function() {
  let timeControl = timeControlSelectWithFriend.value;
  let timeControlRealTimeInput = document.getElementById("time-control-real-time-with-friend");
  let timeControlCorrespondenceInput = document.getElementById("time-control-correspondence-with-friend");
  if (timeControl == "real time") {
    timeControlRealTimeInput.style.display = "block";
  } else if (timeControl == "correspondence") {
    timeControlCorrespondenceInput.style.display = "block";
  }
  else {
    timeControlRealTimeInput.style.display = "none";
    timeControlCorrespondenceInput.style.display = "none";
  }
}

let timeControlSelectWithAI = document.getElementById("time-control-select-with-ai");
timeControlSelectWithAI.onchange = function() {
  let timeControl = timeControlSelectWithAI.value;
  let timeControlRealTimeInput = document.getElementById("time-control-real-time-with-ai");
  let timeControlCorrespondenceInput = document.getElementById("time-control-correspondence-with-ai");
  if (timeControl == "real time") {
    timeControlRealTimeInput.style.display = "block";
  } else if (timeControl == "correspondence") {
    timeControlCorrespondenceInput.style.display = "block";
  }
  else {
    timeControlRealTimeInput.style.display = "none";
    timeControlCorrespondenceInput.style.display = "none";
  }
}


var white_submit_button = document.querySelector('#create-game-as-white-submit-button');
var black_submit_button = document.querySelector('#create-game-as-black-submit-button');
var random_submit_button = document.querySelector('#create-game-as-random-submit-button');

white_submit_button.addEventListener('click', function(event) {
  event.preventDefault();
  handle_create_game_form(this.form, "create-game-as-white-submit-button");
});

black_submit_button.addEventListener('click', function(event) {
  event.preventDefault();
  handle_create_game_form(this.form, "create-game-as-black-submit-button");
});

random_submit_button.addEventListener('click', function(event) {
  event.preventDefault();
  handle_create_game_form(this.form, "create-game-as-random-submit-button");
});


// GAME LIST
let game_list = new GameList(document.getElementById('game_list'));

let open_games_list = [];
let game_list_open_user_game = null;
let game_list_open_game = null;

for (var open_game of open_games.values()) {
  open_game = Object.values(open_game);
  if (user_id !== open_game[0]) {
    game_list_open_game = {game_id: open_game[1], game_creator_id: open_game[0], minutes: open_game[2], increment: open_game[3]};
    open_games_list.push(game_list_open_game);
  } else {
    game_list_open_user_game = {game_id: open_game[1], game_creator_id: open_game[0], minutes: open_game[2], increment: open_game[3]};
  }
}

game_list.add_games(open_games_list);
if (game_list_open_user_game !== null) {
  game_list.set_user_game(game_list_open_user_game);
  game_list.show_user_game();
}

///

function handle_create_game_form(form, button_id) {
  var iterator = new FormData(form).entries();
  var data = iterator.next();
  var kv = new Map();

  while(data.done === false) {
    kv.set(data.value[0], data.value[1])
    data = iterator.next();
  }

  switch(button_id) {
    case "create-game-as-white-submit-button":
      kv.set("color", "white")
      break;
    case "create-game-as-black-submit-button":
      kv.set("color", "black")
      break;
    case "create-game-as-random-submit-button":
      kv.set("color", "rand")
      break;
    default:
      break;
  }

  form_data = new URLSearchParams(Object.fromEntries(kv));
  fetch('/setup/game', {
    method: 'POST',
    body: form_data,
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded'
    }
  })
  .then(response => {
    if (response.ok) {
      user_game = {game_creator_id: kv.get("color"), time: kv.get("minutes")};
      game_list.set_user_game(user_game);
      game_list.show_user_game();
      createGameModal.style.display = "none";
    } else {
      // Handle errors or other non-successful responses here
    }
  })
  .catch(error => {
    // Handle network errors or exceptions here
  });
}
