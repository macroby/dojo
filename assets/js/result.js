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