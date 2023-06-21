

%%raw(`
class Result {
    constructor(element) {
        this.result = element;
        this.result.style.display =  'none';
    }

    showResult() {
        this.result.style.display = 'block';
    }

    hideResult() {
        this.result.style.display = 'none';
    }

    setResult(result) {
        this.result.innerHTML = result;
    }
}
export default Result;
`)

type rescript_result ={
    element: React.element,
}

// let rescript_result_test = () => {
//     let element = <h1> {React.string("Hello World")} </h1>

//     switch ReactDOM.querySelector("#result") {
//     | Some(resultElement) => {
//         let result = ReactDOM.Client.createRoot(resultElement)
//         ReactDOM.Client.Root.render(result, element)
//         }
//     | None => ()
//     }
// }