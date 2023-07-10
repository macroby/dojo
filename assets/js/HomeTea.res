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
  | InitializeUserChannel(Phoenix.channel)

type model = {
  user_token: string,
  csrf_token: string,
  user_id: string,
  open_games: Belt.Array.t<open_game>,
  user_channel: option<Phoenix.channel>,
}

let init = () => (
  {
    user_token: %raw(`user_token`),
    csrf_token: %raw(`csrf_token`),
    user_id: %raw(`user_id`),
    open_games: %raw(`open_games`),
    user_channel: None,
  },
  Tea_cmd.none,
)

let update = (model: model, msg: msg) =>
  switch msg {
  // TODO: move modal opening to view
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
      switch Belt.Option.isSome(model.user_channel) {
      | true => Phoenix.push(Belt.Option.getExn(model.user_channel), "accept", {"game_id": game_id})
      | false => ()
      }
      (model, Tea_cmd.none)
    }
  | CancelUserGame(game_id) => {
      switch Belt.Option.isSome(model.user_channel) {
      | true => Phoenix.push(Belt.Option.getExn(model.user_channel), "cancel", {"game_id": game_id})
      | false => ()
      }
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
  | InitializeUserChannel(user_channel) => (
      {...model, user_channel: Some(user_channel)},
      Tea_cmd.none,
    )
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

let createGameModalView = (model: model): Vdom.t<msg> => {
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
                list{text("x")},
              ),
              form(
                list{Attributes.id("create-game-form")},
                list{
                  // label(list{Attributes.for'("variant-select")}, list{text("Variant")}),
                  // select(
                  //   list{Attributes.name("variant"), Attributes.id("variant-select-create-game")},
                  //   list{option(list{Attributes.value("standard")}, list{text("Standard")})},
                  // ),
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
                      Attributes.value(model.csrf_token),
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

let playWithFriendModalView = (model: model): Vdom.t<msg> => {
  div(
    list{Attributes.id("playWithFriendModal"), Attributes.class("modal")},
    list{
      div(
        list{Attributes.class("modal-content")},
        list{
          span(
            list{Attributes.id("playWithFriendClose"), Attributes.class("close")},
            list{text("x")},
          ),
          form(
            list{
              Attributes.id("play-with-friend-form"),
              Attributes.action("/setup/friend"),
              Attributes.method("post"),
            },
            list{
              // label(list{}, list{text("Variant")}),
              // select(
              //   list{Attributes.name("variant"), Attributes.id("variant-select-with-friend")},
              //   list{option(list{Attributes.value("standard")}, list{text("Standard")})},
              // ),
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
              input'(
                list{
                  Attributes.type'("hidden"),
                  Attributes.name("_csrf_token"),
                  Attributes.value(model.csrf_token),
                },
                list{},
              ),
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

let playWithComputerModalView = (model: model): Vdom.t<msg> => {
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
                  // label(list{}, list{text("Variant")}),
                  // select(
                  //   list{Attributes.name("variant"), Attributes.id("variant-select")},
                  //   list{option(list{Attributes.value("standard")}, list{text("Standard")})},
                  // ),
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
                  label(list{Attributes.for'("difficulty-select")}, list{text("Difficulty")}),
                  select(
                    list{Attributes.name("difficulty"), Attributes.id("difficulty-select-with-ai")},
                    list{
                      option(list{Attributes.value("1")}, list{text("1")}),
                      option(list{Attributes.value("2")}, list{text("2")}),
                      option(list{Attributes.value("3")}, list{text("3")}),
                      option(list{Attributes.value("4")}, list{text("4")}),
                      option(list{Attributes.value("5")}, list{text("5")}),
                      option(list{Attributes.value("6")}, list{text("6")}),
                      option(list{Attributes.value("7")}, list{text("7")}),
                      option(list{Attributes.value("8")}, list{text("8")}),
                    },
                  ),
                  input'(
                    list{
                      Attributes.type'("hidden"),
                      Attributes.name("_csrf_token"),
                      Attributes.value(model.csrf_token),
                    },
                    list{},
                  ),
                  br(list{}),
                  button(
                    list{
                      Attributes.id("play-ai-as-white-submit-button"),
                      Attributes.type'("submit"),
                      Attributes.value("white"),
                      Attributes.name("color"),
                    },
                    list{text("White")},
                  ),
                  button(
                    list{
                      Attributes.id("play-ai-as-black-submit-button"),
                      Attributes.type'("submit"),
                      Attributes.value("black"),
                      Attributes.name("color"),
                    },
                    list{text("Black")},
                  ),
                  button(
                    list{
                      Attributes.id("play-ai-as-random-submit-button"),
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
  )
}

let view = (model: model): Vdom.t<msg> =>
  div(
    list{},
    list{
      div(
        list{Attributes.class("column-sidebar")},
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
      div(
        list{Attributes.class("column-lobby")},
        list{
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
      ),
      createGameModalView(model),
      playWithFriendModalView(model),
      playWithComputerModalView(model),
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
