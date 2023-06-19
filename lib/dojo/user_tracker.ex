defmodule Dojo.UserTracker do
  use GenServer

  require Logger

  alias Dojo.UserTrackerState

  #######
  # API #
  #######

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  def add_open_game(user_id) do
    GenServer.call(__MODULE__, {:add_active_user, user_id})
  end

  def remove_open_game(user_id) do
    GenServer.call(__MODULE__, {:remove_active_user, user_id})
  end

  def get_active_users do
    GenServer.call(__MODULE__, :get_active_users)
  end

  #######################
  # Server Implemention #
  #######################

  def init(_) do
    config = %UserTrackerState{active_users: %{}}
    {:ok, config}
  end

  def handle_call({:add_active_user, active_user}, _from, state) do
    active_users = Map.put(state.active_users, active_user.id, active_user)
    state = %{state | active_users: active_users}

    {:reply, :ok, state}
  end

  def handle_call({:remove_active_user, active_user}, _from, state) do
    active_users = Map.delete(state.active_users, active_user.id)
    state = %{state | active_users: active_users}

    {:reply, :ok, state}
  end

  def handle_call(:get_active_users, _from, state) do
    {:reply, state.active_users, state}
  end
end
