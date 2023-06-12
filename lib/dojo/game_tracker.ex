defmodule Dojo.GameTracker do
  use GenServer

  require Logger

  alias Dojo.GameTrackerState

  #######
  # API #
  #######

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  def add_open_game(game) do
    GenServer.call(__MODULE__, {:add_open_game, game})
  end

  def remove_open_game(game_id) do
    GenServer.call(__MODULE__, {:remove_open_game, game_id})
  end

  def get_open_games do
    GenServer.call(__MODULE__, :get_open_games)
  end

  def get_open_game_ids do
    GenServer.call(__MODULE__, :get_open_game_ids)
  end

  #######################
  # Server Implemention #
  #######################

  def init(_) do
    config = %GameTrackerState{open_games: %{}}
    {:ok, config}
  end

  def handle_call({:add_open_game, game}, _from, state) do
    open_games = Map.put(state.open_games, game.game_id, game)
    state = %{state | open_games: open_games}

    {:reply, :ok, state}
  end

  def handle_call({:remove_open_game, game_id}, _from, state) do
    open_games = Map.delete(state.open_games, game_id)
    state = %{state | open_games: open_games}

    {:reply, :ok, state}
  end

  def handle_call(:get_open_games, _from, state) do
    {:reply, state.open_games, state}
  end

  def handle_call(:get_open_game_ids, _from, state) do
    {:reply, Map.keys(state.open_games), state}
  end
end
