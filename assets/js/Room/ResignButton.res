open Tea.App

open Tea.Html

type msg =
    | ShowResignButton
    | HideResignButton
    | SetOnClick(() => ())
    | Clicked

type model = {
    isResignButtonVisible: bool,
    onClick: option<() => ()>
}

let init = () => { isResignButtonVisible: true, onClick: None }

let update = (model: model, msg: msg) =>
    switch msg {
        | ShowResignButton => { ...model, isResignButtonVisible: true }
        | HideResignButton => { ...model, isResignButtonVisible: false }
        | SetOnClick(onClick) => { ...model, onClick: Some(onClick) }   
        | Clicked => {
            let default = () => {()}
            let onClick = Belt.Option.getWithDefault(model.onClick, default)
            onClick()
            model
        }
    }

let view = (model: model): Vdom.t<msg> =>
    div(
      list{},
      list{ 
        model.isResignButtonVisible != false ? button(list{Events.onClick(Clicked)}, list{text("Resign")}) : noNode
      }  
    )  

let main = beginnerProgram({
    model: init (),
    update: update,
    view: view,
  })
