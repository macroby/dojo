open Tea.App

open Tea.Html

type msg = 
  | CreateGame
  | PlayWithFriend
  | PlayWithComputer

type open_game = 
  {
    "game_id": string,
    "game_creator_id": string,
    "minutes": string,
    "increment": string
  }

type model = 
  { 
    user_token: string,
    csrf_token: string,
    user_id: string,
    open_games: Belt.Array.t<open_game>
  }

let init = () => ({
  user_token: %raw(`user_token`),
  csrf_token: %raw(`csrf_token`),
  user_id: %raw(`user_id`),
  open_games: %raw(`open_games_tea`)
})

let update = (model: model, msg: msg) =>
    switch msg {
        | CreateGame => model
        | PlayWithFriend => model
        | PlayWithComputer => model
    }

let openGameButtons = (model: model) => { 
  let openGameList = model.open_games -> Belt.Array.map(open_game => {
    tr(
      list{Attributes.class("game")}, 
      list{
        th(list{}, list{text("Anon")}),
        th(list{}, list{text("")}),
        open_game["minutes"] == "inf" ? th(list{}, list{text("∞")}) : th(list{}, list{text(open_game["minutes"] ++ " | " ++ open_game["increment"])}),
      })
  })
  Belt.List.fromArray(openGameList)
}

let view = (model: model): Vdom.t<msg> =>
    div(list{}, list{
      div(
        list{},
        list{
          button(
            list{Attributes.id("createGameBtn")},
            list{text("Create Game")}
          ),
          button(
            list{Attributes.id("playWithFriendBtn")},
            list{text("Play With Friend")}
          ),
          button(
            list{Attributes.id("playWithComputerBtn")},
            list{text("Play With Computer")}
          )
        }
      ),
      span(
        list{Attributes.id("game_list")},
        list{ 
          table(
            list{},
            list{
              thead(
                list{}, 
                list{
                  tr(
                    list{}, 
                    list{
                      th(list{}, list{text("Player")}),
                      th(list{}, list{text("Rating")}),
                      th(list{}, list{text("Time")}),
                  })
              }),
              tbody(
                list{}, 
                openGameButtons(model)
              )
            })
        }  
      ) 
    })
    

let main = beginnerProgram({
    model: init (),
    update: update,
    view: view,
  })

@scope("document") external getElementById: string => Js.null_undefined<Dom.node> = "getElementById"

let homeTea = main(getElementById("home_tea"))(())

%%raw(`
import "../css/phoenix.css"
import "../css/app.css"

import GameList from "./game_list"
import "phoenix_html"
`)

let user_token_res: string = %raw(`user_token`)

let socket = Phoenix.newSocket("/user_socket", {token: user_token_res})

Phoenix.connect(socket)

let userIdRes: string = %raw(`user_id`)
let userChannel = Phoenix.newChannel(socket, "home:" ++ userIdRes, {})
let channel = Phoenix.newChannel(socket, "home:lobby", {})

Phoenix.on(userChannel, "redirect", payload => {
    %raw(`location.href = payload.game_id`)
})

Phoenix.on(channel, "closed_game", payload => {
    %raw(`game_list.remove_game(payload.game_id)`)
})

Phoenix.on(channel, "new_game", payload => {
    if (payload["game_creator_id"] !== userIdRes) {
        let new_open_game = {
            "game_id": payload["game_id"],
            "game_creator_id": payload["game_creator_id"],
            "minutes": payload["minutes"],
            "increment": payload["increment"]
        }
        Js.log(new_open_game)
        %raw(`game_list.add_game(new_open_game)`)
    }
})

Phoenix.joinChannel(userChannel)
Phoenix.joinChannel(channel)

%%raw(`
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
`)

%%raw(`
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
game_list.set_user_game_onclick(function(game_id) {
  userChannel.push("cancel", {game_id: game_id})
});

game_list.set_game_onclick(function(game_id) {
  userChannel.push("accept", {game_id: game_id})
});

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
      if (response.redirected == true) {
        window.location.href = response.url;
      } else {
        user_game = 
        {
          game_creator_id: user_id, 
          time_control: kv.get("time-control"),
          minutes: kv.get("minutes"), 
          increment: kv.get("increment"), 
          game_id: response.headers.get("game_id")
        };
        game_list.set_user_game(user_game);
        game_list.show_user_game();
        createGameModal.style.display = "none";
      }
    } else {
      // Handle errors or other non-successful responses here
    }
  })
  .catch(error => {
    // Handle network errors or exceptions here
  });
}
`)

