defmodule Dojo.GameFactory do
  alias Dojo.GameState
  alias Dojo.GameSupervisor
  alias Dojo.GameTracker

  def create_game(game = %GameState{}) do
    pid = GameSupervisor.start_game(game)
    GameTracker.add_open_game(game)
    pid
  end
end
