defmodule Dojo.Game do
use GenServer

  @moduledoc """
  Represents the state of a game board as a genserver. Might need
  to split this up into a supervisor with children at some point
  in the future. This module would become game_supervisor and the
  module one up will become games_supervisor.
  """
  #######
  # API #
  #######

  def start_link([], id) do
    start_link(id)
  end

  def start_link(id) do
    GenServer.start_link(__MODULE__, name: id)
  end

  def get_fen(pid) do
    GenServer.call(pid, :get_fen)
  end

  def stop do
    GenServer.stop(self())
  end

  #######################
  # Server Implemention #
  #######################

  @impl true
  def init(args) do
    Registry.register(GameRegistry, args[:name], args[:name])
    {_, pid} = :binbo.new_server()
    { :ok, :binbo.new_game(pid) }
  end

  @impl true
  def handle_call(:get_fen, _from, state) do
    {:reply, state, state}
  end
end
