%%raw(`
import "../css/app.css"
import "phoenix_html"
`)

@scope("document") external getElementById: string => Js.null_undefined<Dom.node> = "getElementById"
@val external void: 'a => unit = "void"

let user_token_res: string = %raw(`user_token`)

let userIdRes: string = %raw(`user_id`)

let socket = Phoenix.newSocket("/user_socket", {token: user_token_res})

Phoenix.connect(socket)

let userChannel = Phoenix.newChannel(socket, "home:" ++ userIdRes, {})
let channel = Phoenix.newChannel(socket, "home:lobby", {})

let homeTea = HomeTea.main(getElementById("home_tea"))()
homeTea["pushMsg"](InitializeUserChannel(userChannel))

Phoenix.on(userChannel, "redirect", payload => {
  ignore(payload)
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

//
// Control the modals
//
@scope("document") external getElementById: string => 'a = "getElementById"
@scope("document") external querySelector: string => 'a = "querySelector"
@val external this: 'a = "this"
@val external event: 'a = "event"

let createGameModal = getElementById("createGameModal")
let playWithFriendModal = getElementById("playWithFriendModal")
let playWithComputerModal = getElementById("playWithComputerModal")

let createGameBtn = getElementById("createGameBtn")
let playWithFriendBtn = getElementById("playWithFriendBtn")
let playWithComputerBtn = getElementById("playWithComputerBtn")

let createGameSpan = getElementById("createGameClose")
let playWithFriendSpan = getElementById("playWithFriendClose")
let playWithComputerSpan = getElementById("playWithComputerClose")

let white_submit_button = querySelector("#create-game-as-white-submit-button")
let black_submit_button = querySelector("#create-game-as-black-submit-button")
let random_submit_button = querySelector("#create-game-as-random-submit-button")

let timeControlSelectCreateGame = getElementById("time-control-select-create-game")
let timeControlSelectWithFriend = getElementById("time-control-select-with-friend")
let timeControlSelectWithAI = getElementById("time-control-select-with-ai")

createGameSpan["onclick"] = () => createGameModal["style"]["display"] = "none"
playWithFriendSpan["onclick"] = () => playWithFriendModal["style"]["display"] = "none"
playWithComputerSpan["onclick"] = () => playWithComputerModal["style"]["display"] = "none"


// close the modal if the user clicks outside of it
let window = %raw(`window`)
window["onclick"] = event => {
  if event["target"] == createGameModal {
    createGameModal["style"]["display"] = "none"
  }
  if event["target"] == playWithFriendModal {
    playWithFriendModal["style"]["display"] = "none"
  }
  if event["target"] == playWithComputerModal {
    playWithComputerModal["style"]["display"] = "none"
  }
}

timeControlSelectCreateGame["onchange"] = () => {
  let timeControl = timeControlSelectCreateGame["value"]
  let timeControlRealTimeInput = getElementById("time-control-real-time-create-game")
  let timeControlCorrespondenceInput = getElementById("time-control-correspondence-create-game")
  if timeControl == "real time" {
    timeControlRealTimeInput["style"]["display"] = "block"
  } else {
    timeControlRealTimeInput["style"]["display"] = "none"
    timeControlCorrespondenceInput["style"]["display"] = "none"
  }
}

timeControlSelectWithFriend["onchange"] = () => {
  let timeControl = timeControlSelectWithFriend["value"]
  let timeControlRealTimeInput = getElementById("time-control-real-time-with-friend")
  let timeControlCorrespondenceInput = getElementById("time-control-correspondence-with-friend")
  if timeControl == "real time" {
    timeControlRealTimeInput["style"]["display"] = "block"
  } else {
    timeControlRealTimeInput["style"]["display"] = "none"
    timeControlCorrespondenceInput["style"]["display"] = "none"
  }
}

timeControlSelectWithAI["onchange"] = () => {
  let timeControl = timeControlSelectWithAI["value"]
  let timeControlRealTimeInput = getElementById("time-control-real-time-with-ai")
  let timeControlCorrespondenceInput = getElementById("time-control-correspondence-with-ai")
  if timeControl == "real time" {
    timeControlRealTimeInput["style"]["display"] = "block"
  } else {
    timeControlRealTimeInput["style"]["display"] = "none"
    timeControlCorrespondenceInput["style"]["display"] = "none"
  }
}

%%raw(`
white_submit_button.addEventListener('click', function(_) {
  event.preventDefault();
  handle_create_game_form(this.form, "create-game-as-white-submit-button");
});

black_submit_button.addEventListener('click', function(_) {
  event.preventDefault();
  handle_create_game_form(this.form, "create-game-as-black-submit-button");
});

random_submit_button.addEventListener('click', function(_) {
  event.preventDefault();
  handle_create_game_form(this.form, "create-game-as-random-submit-button");
});
`)

%%raw(`
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
