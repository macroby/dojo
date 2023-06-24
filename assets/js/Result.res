open Tea.App

open Tea.Html

type msg =
    | ShowResult
    | HideResult
    | SetResult(string)

type model = {
    result: string,
    isResultVisible: bool,
}

let init = () => { result: "result", isResultVisible: false }

let update = (model: model, msg: msg) =>
    switch msg {
        | ShowResult => { result: model.result, isResultVisible: true }
        | HideResult => { result: model.result, isResultVisible: false }
        | SetResult(result) => { result: result, isResultVisible: model.isResultVisible }
    }

let view = (model: model): Vdom.t<msg> =>
    div(
      list{},
      list{ 
        model.isResultVisible != false ? text(model.result) : noNode,
      }  
    )

let main = beginnerProgram({
    model: init (),
    update: update,
    view: view,
  })