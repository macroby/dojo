class GameList {
    constructor (element) {
        this.element = element;
        this.id = element.id;
        this.element.querySelector('.user_game').onclick = this.user_game_onclick.bind(this);
    }

    hide_user_game() {
        this.element.querySelector('.user_game').style.display = 'none';
    }

    add_game(game) {
        this.element.querySelector('tbody').innerHTML += "<tr class=\"game\"><td>"+ game.player +"</td><td></td><td>"+ game.time +"</td></tr>"
    }

    user_game_onclick() {
        var game = { player: "anon", time: "5+5" };
        this.add_game(game);
        // this.hide_user_game();
    }
}
export default GameList;