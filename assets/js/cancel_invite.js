class CancelInviteButton {
    constructor(element) {
        this.element = element;
        this.id = element.id;
        this.element.innerHTML = 
        '<button id=\"cancel_invite_button\">Cancel</button>'
    }

    onClick(onclick_function) {
        for (const child of this.element.children) {
            child.addEventListener('click', function () { onclick_function() }.bind(this));
        }
    }
}
export default CancelInviteButton;