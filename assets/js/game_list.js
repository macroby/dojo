class GameList {
    constructor (element) {
        this.element = element;
        this.id = element.id;

        element.querySelector('.user_game').onclick = this.user_game_onclick;
    }

    user_game_onclick() {
        alert('user_game_onclick');
    }
}
export default GameList;