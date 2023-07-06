defmodule Dojo.UserTracker do
  use GenServer

  require Logger

  alias Dojo.UserTrackerState
  alias Dojo.ActiveUser

  #######
  # API #
  #######

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  def add_active_user(user_id, game_pid) do
    GenServer.call(__MODULE__, {:add_active_user, user_id, game_pid})
  end

  def remove_active_user(user_id) do
    GenServer.call(__MODULE__, {:remove_active_user, user_id})
  end

  def get_active_user(user_id) do
    GenServer.call(__MODULE__, {:get_active_user, user_id})
  end

  def get_active_users do
    GenServer.call(__MODULE__, :get_active_users)
  end

  def contains_active_user(user_id) do
    GenServer.call(__MODULE__, {:contains_active_user, user_id})
  end

  #######################
  # Server Implemention #
  #######################

  def init(_) do
    config = %UserTrackerState{active_users: Map.new()}
    {:ok, config}
  end

  def handle_call({:add_active_user, user_id, game_pid}, _from, state) do
    active_users = Map.put(state.active_users, user_id, %ActiveUser{game_pid: game_pid})
    state = %{state | active_users: active_users}

    {:reply, :ok, state}
  end

  def handle_call({:remove_active_user, user_id}, _from, state) do
    active_users = Map.delete(state.active_users, user_id)
    state = %{state | active_users: active_users}

    {:reply, :ok, state}
  end

  def handle_call({:get_active_user, user_id}, _from, state) do
    {:reply, Map.get(state.active_users, user_id), state}
  end

  def handle_call(:get_active_users, _from, state) do
    {:reply, state.active_users, state}
  end

  def handle_call({:contains_active_user, user_id}, _from, state) do
    {:reply, Map.has_key?(state.active_users, user_id), state}
  end
end
