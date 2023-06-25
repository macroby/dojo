open Tea.App

open Tea.Html

type promoPromptOption =
    | Queen
    | Rook
    | Bishop
    | Knight
    | Cancel

type msg =
    | ShowPromotionPrompt
    | HidePromotionPrompt
    | SetOrigDest(string, string)
    | SetOnClick((option<string>, option<string>, promoPromptOption) => ())
    | Clicked(promoPromptOption)

type model = {
    origSquare: option<string>,
    destSquare: option<string>,
    isPromotionPromptVisible: bool,
    onClick: option<(option<string>, option<string>, promoPromptOption) => ()>
}

let init = () => { origSquare: None, destSquare: None, isPromotionPromptVisible: false, onClick: None }

let update = (model: model, msg: msg) =>
    switch msg {
        | ShowPromotionPrompt => { ...model, isPromotionPromptVisible: true }
        | HidePromotionPrompt => { ...model, isPromotionPromptVisible: false }
        | SetOrigDest(orig, dest) => { ...model, origSquare: Some(orig), destSquare: Some(dest) }
        | SetOnClick(onClick) => { ...model, onClick: Some(onClick) }   
        | Clicked(promoPromptChoice) => {
            let default = (_string, _string, _promoPromptOption) => {()}
            let onClick = Belt.Option.getWithDefault(model.onClick, default)
            onClick(model.origSquare, model.destSquare, promoPromptChoice)
            { ...model, isPromotionPromptVisible: false }
        }
          
    }

let view = (model: model): Vdom.t<msg> =>
    div(
      list{},
      list{ 
        model.isPromotionPromptVisible != false ? button(list{Events.onClick(Clicked(Queen))}, list{text("Queen")}) : noNode,
        model.isPromotionPromptVisible != false ? button(list{Events.onClick(Clicked(Rook))}, list{text("Rook")}) : noNode,
        model.isPromotionPromptVisible != false ? button(list{Events.onClick(Clicked(Bishop))}, list{text("Bishop")}) : noNode,
        model.isPromotionPromptVisible != false ? button(list{Events.onClick(Clicked(Knight))}, list{text("Knight")}) : noNode,
        model.isPromotionPromptVisible != false ? button(list{Events.onClick(Clicked(Cancel))}, list{text("X")}) : noNode
      }  
    )  

let main = beginnerProgram({
    model: init (),
    update: update,
    view: view,
  })