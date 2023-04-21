class PromotionPrompt {
    constructor(element) {
        this.element = element;
        this.id = element.id;
        this.element.innerHTML = 
        '<button id=\"promoteQueen\">Queen</button>\
         <button id=\"promoteRook\">Rook</button>\
         <button id=\"promoteBishop\">Bishop</button>\
         <button id=\"promoteKnight\">Knight</button>\
         <button id=\"promoteCancel\">X</button>';
    }

    reveal() {
        this.element.style.display = 'block';
    }

    set_orig_dest(orig, dest) {
        this.orig = orig;
        this.dest = dest;
    }

    set_onclick(onclick) {
        for (const child of this.element.children) {
            let piece;
            switch (child.id) {
                case 'promoteQueen':
                    piece = 'q';
                    break;
                case 'promoteRook':
                    piece = 'r';
                    break;
                case 'promoteBishop':
                    piece = 'b';
                    break;
                case 'promoteKnight':
                    piece = 'n';
                    break;
                case 'promoteCancel':
                    piece = 'c';
                    break;
            }

            child.addEventListener('click', function () { this.parentElement.style.display = 'none'; });

            child.addEventListener('click', function () { onclick(this.orig, this.dest, piece) }.bind(this));
        }
    }
}
export default PromotionPrompt;