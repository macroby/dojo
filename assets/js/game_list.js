class GameList {
    constructor (element) {
        this.element = element;
        this.id = element.id;
        this.game_map = new Map();

        this.element.querySelector('.user_game').onclick = this.user_game_onclick.bind(this);
    }

    hide_user_game() {
        this.element.querySelector('.user_game').style.display = 'none';
    }

    show_user_game() {
        this.element.querySelector('.user_game').style.display = 'block';
    }

    add_games(games) {
        for(var i = 0; i < games.length; i++) {
            const id = games[i].id;
            this.game_map.set(id, games[i]);
        }
        this.render_from_game_map();
    }

    add_game(game) {
        this.game_map.set(game.id, game);
        this.render_from_game_map();
    }

    remove_game(game_id) {
        this.game_map.delete(game_id);
        this.render_from_game_map();
    }

    render_from_game_map() {
        this.element.querySelector('tbody').innerHTML = "<tr class=\"user_game\"><td>anon</td><td></td><td>5+3</td></tr>";
        this.game_map.forEach((value, key) => {
            this.element.querySelector('tbody').innerHTML += "<tr class=\"game\"><td>"+ value.player +"</td><td></td><td>"+ value.time +"</td></tr>"
        });
        this.element.querySelector('.user_game').onclick = this.user_game_onclick.bind(this);

        var game_children = this.element.querySelectorAll('.game');
        for(var i = 0; i < game_children.length; i++) {
            game_children[i].onclick = this.game_onclick.bind(this);
        }
    }

    user_game_onclick() {
        var game1 = { player: "anon", time: "5+5", id: "12345"};
        var game2 = { player: "anon", time: "5+5", id: "12346"};
        var game3 = { player: "anon", time: "5+5", id: "12347"};
        var game4 = { player: "anon", time: "5+5", id: "12348"};

        var games = [game1, game2, game3, game4];

        this.add_games(games);
        // this.hide_user_game();
    }

    game_onclick() {
        this.remove_game("12345");
    }
}
export default GameList;