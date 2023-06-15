import { render } from "chessground/anim";

class GameList {
    constructor (element) {
        this.element = element;
        this.game_map = new Map();
        this.user_game = null;
        this.user_game_callback = null;
        this.game_callback = null;
    }

    // need init function for rendering the game list

    hide_user_game() {
        this.element.querySelector('.user_game').style.display = 'none';
    }

    show_user_game() {
        this.element.querySelector('.user_game').style.display = 'table-row';
    }

    set_user_game(game) {
        this.user_game = game;
        this.render();
    }

    add_games(games) {
        for(var i = 0; i < games.length; i++) {
            this.game_map.set(games[i].game_id, games[i]);
        }
        this.render();
    }

    add_game(game) {
        this.game_map.set(game.game_id, game);
        this.render();
    }

    remove_game(game_id) {
        this.game_map.delete(game_id);
        this.render();
    }

    render() {
        if (this.user_game == null) {
            // dont render the user game if it is null
        } else if (this.user_game.minutes == "inf" || this.user_game.increment == "inf") {
            this.element.querySelector('.user_game').innerHTML = "<td>"+ this.user_game.game_creator_id +"</td><td>" + this.user_game.game_id + "</td><td>∞</td>";
        } else {
            this.element.querySelector('.user_game').innerHTML = 
                "<td>"+ this.user_game.game_creator_id +"</td><td>" + this.user_game.game_id + "</td><td>"+ this.user_game.minutes + "+" + this.user_game.increment +"</td>";
        }
        this.game_map.forEach((value, key) => {
            if (value.minutes == "inf" || value.increment == "inf") {
                this.element.querySelector('tbody').innerHTML += "<tr class=\"game\"><td>"+ value.game_creator_id +"</td><td>" + value.game_id + "</td><td>∞</td></tr>"
            } else {
                this.element.querySelector('tbody').innerHTML += "<tr class=\"game\"><td>"+ value.game_creator_id +"</td><td>" + value.game_id + "</td><td>"+ value.minutes + "+" + value.increment +"</td></tr>"
            }
        });
        
        if (this.user_game_callback != null) {
            this.element.querySelector('.user_game').addEventListener('click', function() {
                this.user_game_callback();
            }.bind(this));
        }

        if (this.game_callback != null) {
            var game_children = this.element.querySelectorAll('.game');
            var game_id_iter = this.game_map.keys();
            for(var i = 0; i < game_children.length; i++) {
                game_children[i].addEventListener('click', function() {
                    this.game_callback(game_id_iter.next().value);
                }.bind(this));
            }
        }
    }

    set_user_game_onclick(callback) {
        this.user_game_callback = callback;
    }

    set_game_onclick(callback) {
        this.game_callback = callback;
    }
}
export default GameList;