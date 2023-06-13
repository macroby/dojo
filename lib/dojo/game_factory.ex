defmodule Dojo.GameFactory do
  alias Dojo.GameState
  alias Dojo.GameSupervisor
  alias Dojo.GameTracker

  def create_game(game = %GameState{}) do
    pid = GameSupervisor.start_game(game)

    case game.game_type do
      :open -> GameTracker.add_open_game(game)
      # GameTracker.add_private_game(game)
      _ -> nil
    end

    pid
  end
end
