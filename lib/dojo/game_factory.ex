defmodule Dojo.GameFactory do
  alias Dojo.GameState
  alias Dojo.GameSupervisor

  def create_game(game = %GameState{}) do
    pid = GameSupervisor.start_game(game)
    pid
  end
end
