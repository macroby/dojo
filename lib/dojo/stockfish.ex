defmodule Dojo.Stockfish do
  use GenServer
  require Logger

  @moduledoc """
  A wrapper around the stockfish chess engine. Each instance of a stockfish
  process is a genserver that can be called to make moves. Multiple stockfish
  processes can be started and each one can be used by more than one game.
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

  defp via_tuple(name),
    do: {:via, Registry, {StockfishRegistry, name}}

  def find_best_move(p_name, fen, time, depth) do
    GenServer.call(p_name, {:find_best_move, fen, time, depth})
  end

  def find_best_move(p_name, fen, depth) do
    GenServer.call(p_name, {:find_best_move, fen, depth})
  end

  #######################
  # Server Implemention #
  #######################

  def init(config) do
    {:ok, pid} = :binbo.new_server()
    :binbo.new_uci_game(pid, %{engine_path: "/home/md/dojo/stockfish_15.1_x64_bmi2"})

    {:ok, %{inner_pid: pid, id: config.id}}
  end

  def handle_call({:find_best_move, fen, difficulty}, _from, state) do
    skill_level = case difficulty do
      1 -> 0
      2 -> 1
      3 -> 2
      4 -> 5
      5 -> 8
      6 -> 10
      7 -> 15
      8 -> 20
    end
    :binbo.uci_set_position(state.inner_pid, fen)
    :binbo.uci_command_call(state.inner_pid, "setoption name Skill Level value #{skill_level}")
    {:ok, best_move} = :binbo.uci_bestmove(state.inner_pid)
    {:reply, best_move, state}
  end
end
