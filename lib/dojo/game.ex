defmodule Dojo.Game do
use GenServer

  @moduledoc """
  Represents the state of a game. Might need
  to split this up into a supervisor with children at some point
  in the future.
  """
  #######
  # API #
  #######


  @doc """
  A wrapper around start_link(id), so that it plays
  nice with dynamic supervisor start_child.

  Returns same results as GenServer.start_link().
  """
  def start_link([], config) do
    start_link(config)
  end

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: via_tuple(config.id))
  end

  defp via_tuple(name) ,
    do: {:via, Registry, {GameRegistry, name} }

  def get_info(p_name) do
    GenServer.call(p_name, :get_info)
  end

  def get_fen(p_name) do
    GenServer.call(p_name, :get_fen)
  end

  def stop do
    GenServer.stop(self())
  end

  #######################
  # Server Implemention #
  #######################

  @impl true
  def init(config) do
    # Registry.register(GameRegistry, args[:name], args[:name])
    {_, pid} = :binbo.new_server()
    :binbo.new_game(pid)
    {:ok, %{board_pid: pid, color: config.color}}
  end

  @impl true
  def handle_call(:get_fen, _from, state) do
    {_, fen} = :binbo.get_fen(state.board_pid)
    {:reply, fen, state}
  end

  @impl true
  def handle_call(:get_info, _from, state) do
    {:reply, state, state}
  end
end
