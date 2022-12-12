defmodule Dojo.Game do
use GenServer

  @moduledoc """
  Represemts the state of a game board as a genserver.
  """
  #######
  # API #
  #######


  @doc """
  Create the board server.
      iex> BoardServer.start
      :ok
  """

  def start(name) do
    GenServer.start(__MODULE__, name: name)
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
