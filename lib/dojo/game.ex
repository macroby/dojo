defmodule Dojo.Game do
  use GenServer
  require Logger

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

  defp via_tuple(name),
    do: {:via, Registry, {GameRegistry, name}}

  def get_state(p_name) do
    GenServer.call(p_name, :get_state)
  end

  def get_fen(p_name) do
    GenServer.call(p_name, :get_fen)
  end

  def make_move(p_name, move) do
    GenServer.call(p_name, {:make_move, move})
  end

  def get_all_legal_moves_bin(p_name) do
    GenServer.call(p_name, :get_all_legal_moves_bin)
  end

  def get_all_legal_moves_str(p_name) do
    GenServer.call(p_name, :get_all_legal_moves_str)
  end

  def get_side_to_move(p_name) do
    GenServer.call(p_name, :get_side_to_move)
  end

  def get_halfmove_clock(p_name) do
    GenServer.call(p_name, :get_halfmove_clock)
  end

  def stop do
    GenServer.stop(self())
  end

  #######################
  # Server Implemention #
  #######################

  @impl true
  def init(config) do
    {_, pid} = :binbo.new_server()
    :binbo.new_game(pid)

    {_, fen} = :binbo.get_fen(pid)

    dests =
      case :binbo.all_legal_moves(pid, :str) do
        {:error, reason} -> raise reason
        {:ok, movelist} -> movelist
      end

    clock_pid =
      case Dojo.Clock.start_link(%{time_control: config.time_control, increment: config.increment}) do
        {:error, reason} -> raise reason
        {:ok, pid} -> pid
      end

    {:ok,
     %{
       board_pid: pid,
       color: config.color,
       fen: fen,
       dests: dests,
       halfmove_clock: 0,
       time_control: config.time_control,
       increment: config.increment,
       clock_pid: clock_pid
     }}
  end

  @impl true
  def handle_call(:get_fen, _from, state) do
    {_, fen} = :binbo.get_fen(state.board_pid)
    {:reply, fen, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:make_move, move}, _from, state) do
    case :binbo.move(state.board_pid, move) do
      {:error, reason} ->
        {:reply, {:error, reason}, state}

      {:ok, _} ->
        {_, fen} = :binbo.get_fen(state.board_pid)

        halfmove_clock = state.halfmove_clock + 1

        Dojo.Clock.switch_turn_color(state.clock_pid)

        if halfmove_clock == 2 do
          Dojo.Clock.start_clock(state.clock_pid)
        end

        dests =
          case :binbo.all_legal_moves(state.board_pid, :str) do
            {:error, reason} -> raise reason
            {:ok, movelist} -> movelist
          end

        state = Map.replace(state, :fen, fen)
        state = Map.replace(state, :dests, dests)
        state = Map.replace(state, :halfmove_clock, halfmove_clock)

        clock_state = Dojo.Clock.get_clock_state(state.clock_pid)
        Logger.debug("testing the clock")
        Logger.debug("WHITE")
        Logger.debug(["time left", " ", Integer.to_string(clock_state.white_time_milli)])

        Logger.debug("BLACK")
        Logger.debug(["time left", " ", Integer.to_string(clock_state.black_time_milli)])

        {:reply, {:ok, fen}, state}
    end
  end

  @impl true
  def handle_call(:get_all_legal_moves_bin, _from, state) do
    movelist =
      case :binbo.all_legal_moves(state.board_pid, :bin) do
        {:error, reason} -> raise reason
        {:ok, movelist} -> movelist
      end

    {:reply, movelist, state}
  end

  @impl true
  def handle_call(:get_all_legal_moves_str, _from, state) do
    movelist =
      case :binbo.all_legal_moves(state.board_pid, :str) do
        {:error, reason} -> raise reason
        {:ok, movelist} -> movelist
      end

    {:reply, movelist, state}
  end

  @impl true
  def handle_call(:get_side_to_move, _from, state) do
    side_to_move =
      case :binbo.side_to_move(state.board_pid) do
        {:error, reason} -> raise reason
        {:ok, side_to_move} -> side_to_move
      end

    {:reply, side_to_move, state}
  end

  @impl true
  def handle_call(:get_halfmove_clock, _from, state) do
    {:reply, state.halfmove_clock, state}
  end
end
