open Tea.App

open Tea.Html

@scope("document") external getElementById: string => Js.null_undefined<Dom.node> = "getElementById"

@send external floor: float => int = "Math.floor"
@val external void: 'a => unit = "void"

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

type milliseconds = int
type userMilliseconds = milliseconds
type opponentMilliseconds = milliseconds
type fen = string
type dests = string
type color = string
type gameType = string
type inviteAcceptance = string
type increment = string
type whiteClock = milliseconds
type blackClock = milliseconds
type gameStatus = string
type userToken = string
type timeControl = string
type sideToPlay = string
type chessground = unit
type channel = unit
type origin = string
type destination = string
type promoPromptOption =
  | Queen
  | Rook
  | Bishop
  | Knight
  | Cancel

type msg =
  | ShowPromotionPrompt(origin, destination)
  | HidePromotionPrompt
  | PromotionPromptClicked(promoPromptOption)
  | ShowResult(string)
  | UpdateClocksWithServerTime(userMilliseconds, opponentMilliseconds)
  | DecrementUserTime(milliseconds)
  | DecrementOpponentTime(milliseconds)
  | UpdateUserClockTitle(string)
  | UpdateOpponentClockTitle(string)
  | StopClock
  | HideClock
  | ResignButtonClicked
  | Initialize(
      fen,
      dests,
      color,
      gameType,
      inviteAcceptance,
      increment,
      whiteClock,
      blackClock,
      gameStatus,
      userToken,
      timeControl,
      sideToPlay,
      chessground,
      channel,
    )

type model = {
  fen: string,
  dests: string,
  color: string,
  gameType: string,
  inviteAcceptance: string,
  increment: string,
  whiteClock: milliseconds,
  blackClock: milliseconds,
  gameStatus: string,
  userToken: string,
  timeControl: string,
  sideToPlay: string,
  isResignButtonVisible: bool,
  userTimeAsString: string,
  opponentTimeAsString: string,
  userTimeAsMilli: int,
  opponentTimeAsMilli: int,
  userClockTitle: string,
  opponentClockTitle: string,
  clockStopped: bool,
  clockHidden: bool,
  origSquarePromotion: option<string>,
  destSquarePromotion: option<string>,
  isPromotionPromptVisible: bool,
  resultText: string,
  isResultVisible: bool,
  chessground: unit,
  channel: unit,
}

let init = () => {
  (
    {
      fen: "",
      dests: "",
      color: "",
      gameType: "",
      inviteAcceptance: "",
      increment: "",
      whiteClock: 0,
      blackClock: 0,
      gameStatus: "",
      userToken: "",
      timeControl: "",
      sideToPlay: "",
      isResignButtonVisible: true,
      userTimeAsString: "0:00",
      opponentTimeAsString: "0:00",
      userTimeAsMilli: 0,
      opponentTimeAsMilli: 0,
      userClockTitle: "You",
      opponentClockTitle: "Anon",
      clockStopped: false,
      clockHidden: false,
      origSquarePromotion: None,
      destSquarePromotion: None,
      isPromotionPromptVisible: false,
      resultText: "",
      isResultVisible: false,
      chessground: (),
      channel: (),
    },
    Tea_cmd.NoCmd,
  )
}

let update = (model: model, msg: msg) => {
  switch msg {
  | ShowPromotionPrompt(orig, dest) => (
      {
        ...model,
        isPromotionPromptVisible: true,
        origSquarePromotion: Some(orig),
        destSquarePromotion: Some(dest),
      },
      Tea_cmd.NoCmd,
    )
  | HidePromotionPrompt => (
      {
        ...model,
        isPromotionPromptVisible: false,
        origSquarePromotion: None,
        destSquarePromotion: None,
      },
      Tea_cmd.NoCmd,
    )
  | PromotionPromptClicked(promoPromptOption) => {
      let orig_unwrap = Belt.Option.getWithDefault(model.origSquarePromotion, "")
      let dest_unwrap = Belt.Option.getWithDefault(model.destSquarePromotion, "")

      // hack to force the compiler to keep orig_unwrap and dest_unwrap in the js output
      Js.log(orig_unwrap)
      Js.log(dest_unwrap)

      switch promoPromptOption {
      | Cancel => {
          let dests_map = %raw("new Map(Object.entries(model.dests))")
          void(dests_map)
          %raw(`
            model.chessground.set({
              fen: model.fen,
              turnColor: model.color,
              movable: {
                color: model.color,
                dests: dests_map
              }
            })
          `)->ignore
          ()
        }
      | Queen => {
          %raw(`
            model.channel.push('move', { 
              move: sanitise(orig_unwrap).concat(sanitise(dest_unwrap)).concat(sanitise("q")),
            })
          `)->ignore
          ()
        }
      | Rook => {
          %raw(`
            model.channel.push('move', { 
              move: sanitise(orig_unwrap).concat(sanitise(dest_unwrap)).concat(sanitise("r")),
            })
          `)->ignore
          ()
        }
      | Bishop => {
          %raw(`
            model.channel.push('move', { 
              move: sanitise(orig_unwrap).concat(sanitise(dest_unwrap)).concat(sanitise("b")),
            })
          `)->ignore
          ()
        }
      | Knight => {
          %raw(`
            model.channel.push('move', { 
              move: sanitise(orig_unwrap).concat(sanitise(dest_unwrap)).concat(sanitise("n")),
            })
          `)->ignore
          ()
        }
      }
      (model, Tea_cmd.msg(HidePromotionPrompt))
    }
  | ShowResult(result) => switch result {
    | "black" => {
        let resultText = "Black wins"
        ({...model, resultText, isResultVisible: true}, Tea_cmd.NoCmd)
      }
    | "white" => {
        let resultText = "White wins"
        ({...model, resultText, isResultVisible: true}, Tea_cmd.NoCmd)
      }
    | "draw" => {
        let resultText = "Draw"
        ({...model, resultText, isResultVisible: true}, Tea_cmd.NoCmd)
      }
    | other => ({...model, resultText: other, isResultVisible: true}, Tea_cmd.NoCmd)
    }
  | UpdateClocksWithServerTime(userMilliseconds, opponentMilliseconds) =>
    switch model.clockStopped {
    | true => (model, Tea_cmd.none)
    | false => {
        let newUserTimeAsMilli = userMilliseconds
        let newOpponentTimeAsMilli = opponentMilliseconds

        let userMinutes = newUserTimeAsMilli / 1000 / 60
        let userSeconds = mod(newUserTimeAsMilli / 1000, 60)
        let userTenths = mod(newUserTimeAsMilli, 1000) / 100

        let opponentMinutes = newOpponentTimeAsMilli / 1000 / 60
        let opponentSeconds = mod(newOpponentTimeAsMilli / 1000, 60)
        let opponentTenths = mod(newOpponentTimeAsMilli, 1000) / 100

        let newUserTimeAsString = switch userMinutes {
        | 0 =>
          switch userSeconds < 10 {
          | true =>
            let secondsAsString = "0" ++ Js.Int.toString(userSeconds)
            secondsAsString ++ "." ++ Js.Int.toString(userTenths)
          | false => Js.Int.toString(userSeconds) ++ "." ++ Js.Int.toString(userTenths)
          }
        | _ =>
          switch userMinutes < 10 && userSeconds < 10 {
          | true => "0" ++ Js.Int.toString(userMinutes) ++ ":0" ++ Js.Int.toString(userSeconds)
          | false =>
            switch userMinutes < 10 && userSeconds >= 10 {
            | true => "0" ++ Js.Int.toString(userMinutes) ++ ":" ++ Js.Int.toString(userSeconds)
            | false =>
              switch userMinutes >= 10 && userSeconds < 10 {
              | true => Js.Int.toString(userMinutes) ++ ":0" ++ Js.Int.toString(userSeconds)
              | false => Js.Int.toString(userMinutes) ++ ":" ++ Js.Int.toString(userSeconds)
              }
            }
          }
        }

        let newOpponentTimeAsString = switch opponentMinutes {
        | 0 =>
          switch opponentSeconds < 10 {
          | true =>
            let secondsAsString = "0" ++ Js.Int.toString(opponentSeconds)
            secondsAsString ++ "." ++ Js.Int.toString(opponentTenths)
          | false => Js.Int.toString(opponentSeconds) ++ "." ++ Js.Int.toString(opponentTenths)
          }
        | _ =>
          switch opponentMinutes < 10 && opponentSeconds < 10 {
          | true =>
            "0" ++ Js.Int.toString(opponentMinutes) ++ ":0" ++ Js.Int.toString(opponentSeconds)
          | false =>
            switch opponentMinutes < 10 && opponentSeconds >= 10 {
            | true =>
              "0" ++ Js.Int.toString(opponentMinutes) ++ ":" ++ Js.Int.toString(opponentSeconds)
            | false =>
              switch opponentMinutes >= 10 && opponentSeconds < 10 {
              | true => Js.Int.toString(opponentMinutes) ++ ":0" ++ Js.Int.toString(opponentSeconds)
              | false => Js.Int.toString(opponentMinutes) ++ ":" ++ Js.Int.toString(opponentSeconds)
              }
            }
          }
        }
        (
          {
            ...model,
            userTimeAsMilli: userMilliseconds,
            userTimeAsString: newUserTimeAsString,
            opponentTimeAsMilli: opponentMilliseconds,
            opponentTimeAsString: newOpponentTimeAsString,
          },
          Tea_cmd.none,
        )
      }
    }
  | DecrementUserTime(milliseconds) =>
    switch model.clockStopped {
    | true => (model, Tea_cmd.none)
    | false => {
        let newTimeAsMilli = model.userTimeAsMilli - milliseconds

        if newTimeAsMilli < 0 {
          (
            {
              ...model,
              userTimeAsString: "0.0",
              userTimeAsMilli: 0,
              clockStopped: model.clockStopped,
              clockHidden: model.clockHidden,
              userClockTitle: model.userClockTitle,
            },
            Tea_cmd.none,
          )
        } else {
          let minutes = newTimeAsMilli / 1000 / 60
          let seconds = mod(newTimeAsMilli / 1000, 60)
          let tenths = mod(newTimeAsMilli, 1000) / 100

          let newTimeAsString = switch minutes {
          | 0 =>
            switch seconds < 10 {
            | true =>
              let secondsAsString = "0" ++ Js.Int.toString(seconds)
              secondsAsString ++ "." ++ Js.Int.toString(tenths)
            | false => Js.Int.toString(seconds) ++ "." ++ Js.Int.toString(tenths)
            }
          | _ =>
            switch minutes < 10 && seconds < 10 {
            | true => "0" ++ Js.Int.toString(minutes) ++ ":0" ++ Js.Int.toString(seconds)
            | false =>
              switch minutes < 10 && seconds >= 10 {
              | true => "0" ++ Js.Int.toString(minutes) ++ ":" ++ Js.Int.toString(seconds)
              | false =>
                switch minutes >= 10 && seconds < 10 {
                | true => Js.Int.toString(minutes) ++ ":0" ++ Js.Int.toString(seconds)
                | false => Js.Int.toString(minutes) ++ ":" ++ Js.Int.toString(seconds)
                }
              }
            }
          }
          (
            {
              ...model,
              userTimeAsString: newTimeAsString,
              userTimeAsMilli: newTimeAsMilli,
              clockStopped: model.clockStopped,
              clockHidden: model.clockHidden,
              userClockTitle: model.userClockTitle,
            },
            Tea_cmd.none,
          )
        }
      }
    }
  | DecrementOpponentTime(milliseconds) =>
    switch model.clockStopped {
    | true => (model, Tea_cmd.none)
    | false => {
        let newTimeAsMilli = model.opponentTimeAsMilli - milliseconds

        if newTimeAsMilli < 0 {
          (
            {
              ...model,
              opponentTimeAsString: "0.0",
              opponentTimeAsMilli: 0,
              clockStopped: model.clockStopped,
              clockHidden: model.clockHidden,
              opponentClockTitle: model.opponentClockTitle,
            },
            Tea_cmd.none,
          )
        } else {
          let minutes = newTimeAsMilli / 1000 / 60
          let seconds = mod(newTimeAsMilli / 1000, 60)
          let tenths = mod(newTimeAsMilli, 1000) / 100

          let newTimeAsString = switch minutes {
          | 0 =>
            switch seconds < 10 {
            | true =>
              let secondsAsString = "0" ++ Js.Int.toString(seconds)
              secondsAsString ++ "." ++ Js.Int.toString(tenths)
            | false => Js.Int.toString(seconds) ++ "." ++ Js.Int.toString(tenths)
            }
          | _ =>
            switch minutes < 10 && seconds < 10 {
            | true => "0" ++ Js.Int.toString(minutes) ++ ":0" ++ Js.Int.toString(seconds)
            | false =>
              switch minutes < 10 && seconds >= 10 {
              | true => "0" ++ Js.Int.toString(minutes) ++ ":" ++ Js.Int.toString(seconds)
              | false =>
                switch minutes >= 10 && seconds < 10 {
                | true => Js.Int.toString(minutes) ++ ":0" ++ Js.Int.toString(seconds)
                | false => Js.Int.toString(minutes) ++ ":" ++ Js.Int.toString(seconds)
                }
              }
            }
          }
          (
            {
              ...model,
              opponentTimeAsString: newTimeAsString,
              opponentTimeAsMilli: newTimeAsMilli,
              clockStopped: model.clockStopped,
              clockHidden: model.clockHidden,
              opponentClockTitle: model.opponentClockTitle,
            },
            Tea_cmd.none,
          )
        }
      }
    }
  | UpdateUserClockTitle(title) => ({...model, userClockTitle: title}, Tea_cmd.none)
  | UpdateOpponentClockTitle(title) => ({...model, opponentClockTitle: title}, Tea_cmd.none)
  | StopClock => ({...model, clockStopped: true}, Tea_cmd.none)
  | HideClock => ({...model, clockHidden: true}, Tea_cmd.none)
  | ResignButtonClicked => {
      %raw(`
      model.channel.push('resign', {})
      `)->ignore
      (model, Tea_cmd.NoCmd)
    }
  | Initialize(
      fen,
      dests,
      color,
      gameType,
      inviteAcceptance,
      increment,
      whiteClock,
      blackClock,
      gameStatus,
      userToken,
      timeControl,
      sideToPlay,
      chessground,
      channel,
    ) => {
      void(fen)
      void(dests)
      void(color)
      void(gameType)
      void(inviteAcceptance)
      void(increment)
      void(whiteClock)
      void(blackClock)
      void(gameStatus)
      void(userToken)
      void(timeControl)
      void(sideToPlay)

      let batchList = {
        switch color {
        | "white" =>
          list{
            Tea_cmd.msg(UpdateUserClockTitle("Anon(w)")),
            Tea_cmd.msg(UpdateOpponentClockTitle("Anon(b)")),
            Tea_cmd.msg(UpdateClocksWithServerTime(whiteClock, blackClock)),
          }
        | "black" =>
          list{
            Tea_cmd.msg(UpdateUserClockTitle("Anon(b)")),
            Tea_cmd.msg(UpdateOpponentClockTitle("Anon(w)")),
            Tea_cmd.msg(UpdateClocksWithServerTime(blackClock, whiteClock)),
          }
        | _ => list{Tea_cmd.none}
        }
      }

      let batchList = switch timeControl {
      | "real_time" => batchList
      | _ => list{Tea_cmd.msg(HideClock), Tea_cmd.msg(StopClock), ...batchList}
      }

      let batchList = switch gameStatus {
      | "continue" => batchList
      | _ => list{Tea_cmd.msg(ShowResult(gameStatus)), ...batchList}
      }
      (
        {
          ...model,
          fen,
          dests,
          color,
          gameType,
          inviteAcceptance,
          increment,
          whiteClock,
          blackClock,
          gameStatus,
          userToken,
          timeControl,
          sideToPlay,
          chessground,
          channel,
        },
        Tea_cmd.batch(batchList),
      )
    }
  }
}

let view = (model: model): Vdom.t<msg> =>
  div(
    list{Attributes.id("side-bar")},
    list{
      div(
        list{},
        list{
          model.clockHidden == false
            ? text(model.userClockTitle ++ ": " ++ model.userTimeAsString)
            : noNode,
        },
      ),
      div(
        list{},
        list{
          model.clockHidden == false
            ? text(model.opponentClockTitle ++ ": " ++ model.opponentTimeAsString)
            : noNode,
        },
      ),
      div(
        list{},
        list{
          model.isPromotionPromptVisible != false
            ? button(list{Events.onClick(PromotionPromptClicked(Queen))}, list{text("Queen")})
            : noNode,
          model.isPromotionPromptVisible != false
            ? button(list{Events.onClick(PromotionPromptClicked(Rook))}, list{text("Rook")})
            : noNode,
          model.isPromotionPromptVisible != false
            ? button(list{Events.onClick(PromotionPromptClicked(Bishop))}, list{text("Bishop")})
            : noNode,
          model.isPromotionPromptVisible != false
            ? button(list{Events.onClick(PromotionPromptClicked(Knight))}, list{text("Knight")})
            : noNode,
          model.isPromotionPromptVisible != false
            ? button(list{Events.onClick(PromotionPromptClicked(Cancel))}, list{text("X")})
            : noNode,
        },
      ),
      div(
        list{},
        list{
          model.isResignButtonVisible != false
            ? button(list{Events.onClick(ResignButtonClicked)}, list{text("Resign")})
            : noNode,
        },
      ),
      div(list{}, list{model.isResultVisible != false ? text(model.resultText) : noNode}),
    },
  )

let subscriptions = (_model: model) => {
  Tea_sub.none
}

let main = standardProgram({
  init,
  update,
  view,
  subscriptions,
})
