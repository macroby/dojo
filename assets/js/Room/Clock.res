open Tea.App

open Tea.Html

@send external floor: float => int = "Math.floor"

type msg = 
    | DecrementTimeAsMilli(int)
    | IncrementTimeAsMilli(int)
    | SetTimeAsMilli(int)
    | SetTitle(string)
    | Stop
    | Hide

type model = 
    { 
        timeAsString: string,
        timeAsMilli: int,
        title: string,
        stopped: bool,
        hidden: bool
    }

let init = () => ({
    timeAsString: "0.0",
    timeAsMilli: 0,
    title: "Anon",
    stopped: false,
    hidden: false
}, Tea_cmd.none)

let update = (model: model, msg: msg) => 
    switch msg {
        | DecrementTimeAsMilli(value) => {
            switch model.stopped {
                | true => (model, Tea_cmd.none)
                | false => {
                    let newTimeAsMilli = model.timeAsMilli - value
                    
                    if newTimeAsMilli < 0 {
                        ({ timeAsString: "0.0", timeAsMilli: 0, stopped: model.stopped, hidden: model.hidden, title: model.title }, Tea_cmd.none)
                    } else {
                        let minutes = newTimeAsMilli / 1000 / 60
                        let seconds = mod(newTimeAsMilli / 1000, 60)
                        let tenths = mod(newTimeAsMilli, 1000) / 100

                        let newTimeAsString = 
                            switch minutes {
                                | 0 => 
                                    switch seconds < 10 {
                                        | true => 
                                            let secondsAsString = "0" ++ Js.Int.toString(seconds)
                                            secondsAsString ++ "." ++ Js.Int.toString(tenths)
                                        | false => 
                                            Js.Int.toString(seconds) ++ "." ++ Js.Int.toString(tenths)
                                    }
                                | _ => 
                                    switch minutes < 10 && seconds < 10 {
                                        | true =>
                                            "0" ++ Js.Int.toString(minutes) ++ ":0" ++ Js.Int.toString(seconds)
                                        | false =>
                                            switch minutes < 10 && seconds >= 10 {
                                                | true =>
                                                    "0" ++ Js.Int.toString(minutes) ++ ":" ++ Js.Int.toString(seconds)
                                                | false =>
                                                    switch minutes >= 10 && seconds < 10 {
                                                        | true =>
                                                            Js.Int.toString(minutes) ++ ":0" ++ Js.Int.toString(seconds)
                                                        | false =>
                                                            Js.Int.toString(minutes) ++ ":" ++ Js.Int.toString(seconds)
                                                    }
                                            }
                                    }   
                            }
                        ({ timeAsString: newTimeAsString, timeAsMilli: newTimeAsMilli, stopped: model.stopped, hidden: model.hidden, title: model.title }, Tea_cmd.none)
                    }
                }
            }
        }
        | IncrementTimeAsMilli(value) => {
            switch model.stopped {
                | true => (model, Tea_cmd.none)
                | false => {
                    let newTimeAsMilli = model.timeAsMilli + value

                    let minutes = newTimeAsMilli / 1000 / 60
                    let seconds = mod(newTimeAsMilli / 1000, 60)
                    let tenths = mod(newTimeAsMilli, 1000) / 100

                    let newTimeAsString = 
                        switch minutes {
                            | 0 => 
                                switch seconds < 10 {
                                    | true => 
                                        let secondsAsString = "0" ++ Js.Int.toString(seconds)
                                        secondsAsString ++ "." ++ Js.Int.toString(tenths)
                                    | false => 
                                        Js.Int.toString(seconds) ++ "." ++ Js.Int.toString(tenths)
                                }
                            | _ => 
                                switch minutes < 10 && seconds < 10 {
                                    | true =>
                                        "0" ++ Js.Int.toString(minutes) ++ ":0" ++ Js.Int.toString(seconds)
                                    | false =>
                                        switch minutes < 10 && seconds >= 10 {
                                            | true =>
                                                "0" ++ Js.Int.toString(minutes) ++ ":" ++ Js.Int.toString(seconds)
                                            | false =>
                                                switch minutes >= 10 && seconds < 10 {
                                                    | true =>
                                                        Js.Int.toString(minutes) ++ ":0" ++ Js.Int.toString(seconds)
                                                    | false =>
                                                        Js.Int.toString(minutes) ++ ":" ++ Js.Int.toString(seconds)
                                                }
                                }
                                }
                        }
                    ({ ...model, timeAsMilli: newTimeAsMilli, timeAsString: newTimeAsString}, Tea_cmd.none)
                }
            }
        }
        | SetTimeAsMilli(value) => {
            switch model.stopped {
                | true => (model, Tea_cmd.none)
                | false => {
                    let newTimeAsMilli = value

                    let minutes = newTimeAsMilli / 1000 / 60
                    let seconds = mod(newTimeAsMilli / 1000, 60)
                    let tenths = mod(newTimeAsMilli, 1000) / 100

                    let newTimeAsString = 
                        switch minutes {
                            | 0 => 
                                switch seconds < 10 {
                                    | true => 
                                        let secondsAsString = "0" ++ Js.Int.toString(seconds)
                                        secondsAsString ++ "." ++ Js.Int.toString(tenths)
                                    | false => 
                                        Js.Int.toString(seconds) ++ "." ++ Js.Int.toString(tenths)
                                }
                            | _ => 
                                switch minutes < 10 && seconds < 10 {
                                    | true =>
                                        "0" ++ Js.Int.toString(minutes) ++ ":0" ++ Js.Int.toString(seconds)
                                    | false =>
                                        switch minutes < 10 && seconds >= 10 {
                                            | true =>
                                                "0" ++ Js.Int.toString(minutes) ++ ":" ++ Js.Int.toString(seconds)
                                            | false =>
                                                switch minutes >= 10 && seconds < 10 {
                                                    | true =>
                                                        Js.Int.toString(minutes) ++ ":0" ++ Js.Int.toString(seconds)
                                                    | false =>
                                                        Js.Int.toString(minutes) ++ ":" ++ Js.Int.toString(seconds)
                                                }
                                }
                                }
                        }
                    ({ ...model, timeAsMilli: value, timeAsString: newTimeAsString }, Tea_cmd.none)
                }
            }
        }
        | SetTitle(value) => {
            ({ ...model, title: value }, Tea_cmd.none)
        }
        | Stop => {
            ({...model, stopped: true}, Tea_cmd.none)
        }
        | Hide => {
            ({...model, hidden: true}, Tea_cmd.none)
        }
    }

let view = (model: model): Vdom.t<msg> =>
    div(
        list{},
        list{
            model.hidden == false ? text(model.title ++ ": " ++model.timeAsString) : noNode
        }
    )

let subscriptions = _ => Tea_sub.none

let main = standardProgram({
    init: init,
    update: update,
    view: view,
    subscriptions: subscriptions,
  })
