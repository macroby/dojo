open Tea.App

open Tea.Html

@send external floor: float => int = "Math.floor"

type msg = 
    | DecrementTimeAsMilli(int)
    | IncrementTimeAsMilli(int)
    | SetTimeAsMilli(int)
    | Stop

type model = 
    { 
        timeAsString: string,
        timeAsMilli: int,
        stopped: bool
    }

let init = () => {
    timeAsString: "0.00",
    timeAsMilli: 0,
    stopped: false
}

let update = (model: model, msg: msg) => 
    switch msg {
        | DecrementTimeAsMilli(value) => {
            switch model.stopped {
                | true => model
                | false => {
                    let newTimeAsMilli = model.timeAsMilli - value

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
                    if newTimeAsMilli < 0 {
                        { ...model, timeAsMilli: 0, timeAsString: newTimeAsString }
                    } else {
                        { ...model, timeAsMilli: newTimeAsMilli }
                    }
                }
            }
        }
        | IncrementTimeAsMilli(value) => {
            switch model.stopped {
                | true => model
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
                    { ...model, timeAsMilli: newTimeAsMilli, timeAsString: newTimeAsString}
                }
            }
        }
        | SetTimeAsMilli(value) => {
            switch model.stopped {
                | true => model
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
                    { ...model, timeAsMilli: value, timeAsString: newTimeAsString }
                }
            }
        }
        | Stop => {
            { ...model, stopped: true }
        }
    }

let view = (model: model): Vdom.t<msg> =>
    div(
        list{},
        list{
            text(model.timeAsString)
        }
    )

let main = beginnerProgram({
    model: init (),
    update: update,
    view: view,
  })
