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

  @doc """
  """
  def start_link([], id) do
    GenServer.start_link(__MODULE__, name: {:via, Registry, {GameRegistry, id}})
  end

  @doc """
  Create the board server.
      iex> BoardServer.start
      :ok
  """

  def start() do
    GenServer.start(__MODULE__, name: self())
  end


  def stop do
    GenServer.stop(self())
  end

  #######################
  # Server Implemention #
  #######################

  def init(_args) do
    { :ok, :binbo.new_server() }
  end

  def handle_call({ :new_game }, _from, state) do
    {:reply, :binbo.new_game(state), state}
  end

  def handle_call({ :get_fen }, _from, state) do
    {:reply, :binbo.get_fen(state), state}
  end
end
