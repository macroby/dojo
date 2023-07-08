%%raw(`
import "../css/phoenix.css"
import "../css/app.css"
import "phoenix_html"
`)

open Tea.App

open Tea.Html

@scope("document") external getElementById: string => Js.null_undefined<Dom.node> = "getElementById"
@val external void: 'a => unit = "void"
type game_id = string

type open_game = {
  "game_id": string,
  "game_creator_id": string,
  "minutes": string,
  "increment": string,
}

type msg =
  | CreateGame
  | PlayWithFriend
  | PlayWithComputer
  | AcceptOpenGame(game_id)
  | CancelUserGame(game_id)
  | ClosedGameChannelMessage(game_id)
  | NewOpenGameChannelMessage(open_game)

type model = {
  user_token: string,
  csrf_token: string,
  user_id: string,
  open_games: Belt.Array.t<open_game>,
}

let user_token_res: string = %raw(`user_token`)

let userIdRes: string = %raw(`user_id`)

let socket = Phoenix.newSocket("/user_socket", {token: user_token_res})

Phoenix.connect(socket)

let userChannel = Phoenix.newChannel(socket, "home:" ++ userIdRes, {})
let channel = Phoenix.newChannel(socket, "home:lobby", {})

let init = () => (
  {
    user_token: %raw(`user_token`),
    csrf_token: %raw(`csrf_token`),
    user_id: %raw(`user_id`),
    open_games: %raw(`open_games`),
  },
  Tea_cmd.none,
)

let update = (model: model, msg: msg) =>
  switch msg {
  | CreateGame => {
      let createGameModal = %raw(`document.getElementById("createGameModal")`)
      void(createGameModal)
      %raw(`createGameModal.style.display = "block"`)->ignore
      (model, Tea_cmd.none)
    }
  | PlayWithFriend => {
      let playWithFriendModal = %raw(`document.getElementById("playWithFriendModal")`)
      void(playWithFriendModal)
      %raw(`playWithFriendModal.style.display = "block"`)->ignore
      (model, Tea_cmd.none)
    }
  | PlayWithComputer => {
      let playWithComputerModal = %raw(`document.getElementById("playWithComputerModal")`)
      void(playWithComputerModal)
      %raw(`playWithComputerModal.style.display = "block"`)->ignore
      (model, Tea_cmd.none)
    }
  | AcceptOpenGame(game_id) => {
      Phoenix.push(userChannel, "accept", {"game_id": game_id})->ignore
      (model, Tea_cmd.none)
    }
  | CancelUserGame(game_id) => {
      Phoenix.push(userChannel, "cancel", {"game_id": game_id})->ignore
      (model, Tea_cmd.none)
    }
  | ClosedGameChannelMessage(game_id) => {
      let open_games =
        model.open_games->Belt.Array.keep(open_game => open_game["game_id"] != game_id)
      ({...model, open_games}, Tea_cmd.none)
    }
  | NewOpenGameChannelMessage(open_game) => {
      let open_games = Belt.Array.concat(model.open_games, [open_game])
      ({...model, open_games}, Tea_cmd.none)
    }
  }

let openGameButtons = (model: model) => {
  let userGame: ref<option<open_game>> = ref(None)
  let openGameList = model.open_games->Belt.Array.map(open_game => {
    if open_game["game_creator_id"] == model.user_id {
      userGame.contents = Some(open_game)
      noNode
    } else {
      tr(
        list{Attributes.class("game"), Events.onClick(AcceptOpenGame(open_game["game_id"]))},
        list{
          th(list{}, list{text("Anon")}),
          th(list{}, list{text("")}),
          open_game["minutes"] == "inf"
            ? th(list{}, list{text("∞")})
            : th(list{}, list{text(open_game["minutes"] ++ " | " ++ open_game["increment"])}),
        },
      )
    }
  })

  let userGameButton = switch userGame.contents {
  | None => noNode
  | Some(open_game) =>
    tr(
      list{Attributes.class("user_game_tea"), Events.onClick(CancelUserGame(open_game["game_id"]))},
      list{
        th(list{}, list{text("You")}),
        th(list{}, list{text("")}),
        open_game["minutes"] == "inf"
          ? th(list{}, list{text("∞")})
          : th(list{}, list{text(open_game["minutes"] ++ " | " ++ open_game["increment"])}),
      },
    )
  }

  let openGameList = Belt.Array.concat([userGameButton], openGameList)
  Belt.List.fromArray(openGameList)
}

let createGameModalView = (): Vdom.t<msg> => {
  div(
    list{Attributes.id("createGameModal"), Attributes.class("modal")},
    list{
      div(
        list{Attributes.class("modal-content")},
        list{
          div(
            list{},
            list{
              span(
                list{Attributes.id("createGameClose"), Attributes.class("close")},
                list{text("&times;")},
              ),
              form(
                list{Attributes.id("create-game-form")},
                list{
                  label(list{Attributes.for'("variant-select")}, list{text("Variant")}),
                  select(
                    list{Attributes.name("variant"), Attributes.id("variant-select-create-game")},
                    list{option(list{Attributes.value("standard")}, list{text("Standard")})},
                  ),
                  label(list{Attributes.for'("time-control-select")}, list{text("Time Control")}),
                  select(
                    list{
                      Attributes.name("time-control"),
                      Attributes.id("time-control-select-create-game"),
                    },
                    list{
                      option(list{Attributes.value("unlimited")}, list{text("Unlimited")}),
                      option(list{Attributes.value("real time")}, list{text("Real Time")}),
                    },
                  ),
                  div(
                    list{
                      Attributes.id("time-control-real-time-create-game"),
                      Attributes.style("display", "none"),
                    },
                    list{
                      label(
                        list{Attributes.for'("time-control-select-create-game")},
                        list{text("Minutes per side")},
                      ),
                      select(
                        list{
                          Attributes.name("minutes"),
                          Attributes.id("minutes-select-create-game"),
                        },
                        list{
                          option(list{Attributes.value("5")}, list{text("5")}),
                          option(list{Attributes.value("10")}, list{text("10")}),
                          option(list{Attributes.value("15")}, list{text("15")}),
                          option(list{Attributes.value("30")}, list{text("30")}),
                        },
                      ),
                      label(
                        list{Attributes.for'("increment-select")},
                        list{text("Increment in seconds")},
                      ),
                      select(
                        list{
                          Attributes.name("increment"),
                          Attributes.id("increment-select-create-game"),
                        },
                        list{
                          option(list{Attributes.value("0")}, list{text("0")}),
                          option(list{Attributes.value("3")}, list{text("3")}),
                          option(list{Attributes.value("5")}, list{text("5")}),
                          option(list{Attributes.value("10")}, list{text("10")}),
                          option(list{Attributes.value("20")}, list{text("20")}),
                        },
                      ),
                    },
                  ),
                  input'(
                    list{
                      Attributes.type'("hidden"),
                      Attributes.name("_csrf_token"),
                      Attributes.value("<%= @csrf_token %>"),
                    },
                    list{},
                  ),
                  br(list{}),
                  div(
                    list{Attributes.id("create-game-submit-buttons")},
                    list{
                      button(
                        list{
                          Attributes.id("create-game-as-white-submit-button"),
                          Attributes.type'("submit"),
                          Attributes.value("white"),
                          Attributes.name("color"),
                        },
                        list{text("White")},
                      ),
                      button(
                        list{
                          Attributes.id("create-game-as-black-submit-button"),
                          Attributes.type'("submit"),
                          Attributes.value("black"),
                          Attributes.name("color"),
                        },
                        list{text("Black")},
                      ),
                      button(
                        list{
                          Attributes.id("create-game-as-random-submit-button"),
                          Attributes.type'("submit"),
                          Attributes.value("rand"),
                          Attributes.name("color"),
                        },
                        list{text("Random")},
                      ),
                    },
                  ),
                },
              ),
            },
          ),
        },
      ),
    },
  )
}

let playWithFriendModalView = (): Vdom.t<msg> => {
  div(
    list{Attributes.id("playWithFriendModal"), Attributes.class("modal")},
    list{
      div(
        list{Attributes.class("modal-content")},
        list{
          span(
            list{Attributes.id("playWithFriendClose"), Events.onClick(PlayWithFriend)},
            list{text("×")},
          ),
          form(
            list{
              Attributes.id("play-with-friend-form"),
              Attributes.action("/setup/friend"),
              Attributes.method("post"),
            },
            list{
              label(list{}, list{text("Variant")}),
              select(
                list{Attributes.name("variant"), Attributes.id("variant-select-with-friend")},
                list{option(list{Attributes.value("standard")}, list{text("Standard")})},
              ),
              label(list{}, list{text("Time Control")}),
              select(
                list{
                  Attributes.name("time-control"),
                  Attributes.id("time-control-select-with-friend"),
                },
                list{
                  option(list{Attributes.value("unlimited")}, list{text("Unlimited")}),
                  option(list{Attributes.value("real time")}, list{text("Real Time")}),
                },
              ),
              div(
                list{
                  Attributes.id("time-control-real-time-with-friend"),
                  Attributes.style("display", "none"),
                },
                list{
                  label(
                    list{Attributes.for'("time-control-select-with-friend")},
                    list{text("Minutes per side")},
                  ),
                  select(
                    list{Attributes.name("minutes"), Attributes.id("minutes-select-with-friend")},
                    list{
                      option(list{Attributes.value("5")}, list{text("5")}),
                      option(list{Attributes.value("10")}, list{text("10")}),
                      option(list{Attributes.value("15")}, list{text("15")}),
                      option(list{Attributes.value("30")}, list{text("30")}),
                    },
                  ),
                  label(
                    list{Attributes.for'("increment-select")},
                    list{text("Increment in seconds")},
                  ),
                  select(
                    list{Attributes.name("increment"), Attributes.id("increment-select")},
                    list{
                      option(list{Attributes.value("0")}, list{text("0")}),
                      option(list{Attributes.value("1")}, list{text("1")}),
                      option(list{Attributes.value("2")}, list{text("2")}),
                      option(list{Attributes.value("3")}, list{text("3")}),
                      option(list{Attributes.value("5")}, list{text("5")}),
                      option(list{Attributes.value("10")}, list{text("10")}),
                      option(list{Attributes.value("15")}, list{text("15")}),
                      option(list{Attributes.value("20")}, list{text("20")}),
                    },
                  ),
                },
              ),
              input'(list{Attributes.type'("submit"), Attributes.value("Play")}, list{}),
              br(list{}),
              button(
                list{
                  Attributes.id("play-friend-as-white-submit-button"),
                  Attributes.type'("submit"),
                  Attributes.value("white"),
                  Attributes.name("color"),
                },
                list{text("White")},
              ),
              button(
                list{
                  Attributes.id("play-friend-as-black-submit-button"),
                  Attributes.type'("submit"),
                  Attributes.value("black"),
                  Attributes.name("color"),
                },
                list{text("Black")},
              ),
              button(
                list{
                  Attributes.id("play-friend-as-random-submit-button"),
                  Attributes.type'("submit"),
                  Attributes.value("rand"),
                  Attributes.name("color"),
                },
                list{text("Random")},
              ),
            },
          ),
        },
      ),
    },
  )
}

let playWithComputerModalView = (): Vdom.t<msg> => {
  div(
    list{},
    list{
      div(
        list{Attributes.id("playWithComputerModal"), Attributes.class("modal")},
        list{
          div(
            list{Attributes.class("modal-content")},
            list{
              span(
                list{Attributes.id("playWithComputerClose"), Attributes.class("close")},
                list{text("x")},
              ),
              form(
                list{
                  Attributes.id("play-with-computer-form"),
                  Attributes.action("/setup/ai"),
                  Attributes.method("post"),
                },
                list{
                  label(list{}, list{text("Variant")}),
                  select(
                    list{Attributes.name("variant"), Attributes.id("variant-select")},
                    list{option(list{Attributes.value("standard")}, list{text("Standard")})},
                  ),
                  label(list{}, list{text("Time Control")}),
                  select(
                    list{
                      Attributes.name("time-control"),
                      Attributes.id("time-control-select-with-ai"),
                    },
                    list{
                      option(list{Attributes.value("unlimited")}, list{text("Unlimited")}),
                      option(list{Attributes.value("real time")}, list{text("Real Time")}),
                    },
                  ),
                  div(
                    list{
                      Attributes.id("time-control-real-time-with-ai"),
                      Attributes.style("display", "none"),
                    },
                    list{
                      label(
                        list{Attributes.for'("time-control-select-with-ai")},
                        list{text("Minutes per side")},
                      ),
                      select(
                        list{Attributes.name("minutes"), Attributes.id("minutes-select-with-ai")},
                        list{
                          option(list{Attributes.value("1")}, list{text("1")}),
                          option(list{Attributes.value("3")}, list{text("3")}),
                          option(list{Attributes.value("5")}, list{text("5")}),
                          option(list{Attributes.value("10")}, list{text("10")}),
                          option(list{Attributes.value("15")}, list{text("15")}),
                          option(list{Attributes.value("30")}, list{text("30")}),
                        },
                      ),
                      label(
                        list{Attributes.for'("increment-select")},
                        list{text("Increment in seconds")},
                      ),
                      select(
                        list{
                          Attributes.name("increment"),
                          Attributes.id("increment-select-with-ai"),
                        },
                        list{
                          option(list{Attributes.value("0")}, list{text("0")}),
                          option(list{Attributes.value("3")}, list{text("3")}),
                          option(list{Attributes.value("5")}, list{text("5")}),
                          option(list{Attributes.value("10")}, list{text("10")}),
                          option(list{Attributes.value("20")}, list{text("20")}),
                        },
                      ),
                    },
                  ),
                },
              ),
            },
          ),
        },
      ),
    },
  )
}

let view = (model: model): Vdom.t<msg> =>
  div(
    list{},
    list{
      div(
        list{},
        list{
          button(
            list{Attributes.id("createGameBtn"), Events.onClick(CreateGame)},
            list{text("Create A Game")},
          ),
          button(
            list{Attributes.id("playWithFriendBtn"), Events.onClick(PlayWithFriend)},
            list{text("Play With Friend")},
          ),
          button(
            list{Attributes.id("playWithComputerBtn"), Events.onClick(PlayWithComputer)},
            list{text("Play With Computer")},
          ),
        },
      ),
      createGameModalView(),
      playWithFriendModalView(),
      playWithComputerModalView(),
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
                    },
                  ),
                },
              ),
              tbody(list{}, openGameButtons(model)),
            },
          ),
        },
      ),
    },
  )

let subscriptions: model => Tea_sub.t<'b> = _model => {
  Tea_sub.none
}

let main = standardProgram({
  init,
  update,
  view,
  subscriptions,
})

let homeTea = main(getElementById("home_tea"))()

Phoenix.on(userChannel, "redirect", payload => {
  %raw(`location.href = payload.game_id`)
})

Phoenix.on(channel, "closed_game", payload => {
  homeTea["pushMsg"](ClosedGameChannelMessage(payload["game_id"]))
})

Phoenix.on(channel, "new_game", payload => {
  if payload["game_creator_id"] !== userIdRes {
    let new_open_game = {
      "game_id": payload["game_id"],
      "game_creator_id": payload["game_creator_id"],
      "minutes": payload["minutes"],
      "increment": payload["increment"],
    }
    homeTea["pushMsg"](NewOpenGameChannelMessage(new_open_game))
  } else {
    homeTea["pushMsg"](
      NewOpenGameChannelMessage({
        "game_id": payload["game_id"],
        "game_creator_id": payload["game_creator_id"],
        "minutes": payload["minutes"],
        "increment": payload["increment"],
      }),
    )
  }
})

Phoenix.joinChannel(userChannel)
Phoenix.joinChannel(channel)

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
