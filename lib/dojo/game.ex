defmodule Dojo.Game do
  use GenServer
  require Logger

  @moduledoc """
  Represents the state of a game.
  """
  alias Dojo.Game

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
    GenServer.start_link(__MODULE__, config, name: via_tuple(config.game_id))
  end

  defp via_tuple(name),
    do: {:via, Registry, {GameRegistry, name}}

  def make_move(p_name, move) do
    GenServer.call(p_name, {:make_move, move})
  end

  def get_state(p_name) do
    GenServer.call(p_name, :get_state)
  end

  def get_fen(p_name) do
    GenServer.call(p_name, :get_fen)
  end

  def get_clock_pid(p_name) do
    GenServer.call(p_name, :get_clock_pid)
  end

  def get_all_legal_moves(p_name) do
    GenServer.call(p_name, :get_all_legal_moves)
  end

  @spec get_side_to_move(atom | pid | {atom, any} | {:via, atom, any}) :: any
  def get_side_to_move(p_name) do
    GenServer.call(p_name, :get_side_to_move)
  end

  def get_halfmove_clock(p_name) do
    GenServer.call(p_name, :get_halfmove_clock)
  end

  def get_game_status(p_name) do
    GenServer.call(p_name, :get_game_status)
  end

  def resign(p_name, side_to_resign) do
    GenServer.call(p_name, {:resign, side_to_resign})
  end

  def stop do
    GenServer.stop(self())
  end

  #######################
  # Server Implemention #
  #######################

  defstruct [
    :game_id,
    :board_pid,
    :color,
    :fen,
    :dests,
    :halfmove_clock,
    :status,
    :time_control,
    :minutes,
    :increment,
    :clock_pid,
    :white_time_ms,
    :black_time_ms,
    :difficulty,
    :status
  ]

  @impl true
  def init(config = %Game{}) do
    {_, pid} = :binbo.new_server()
    :binbo.new_game(pid, "r3k1nr/ppp1ppPp/3p4/8/8/8/PPPPPP1P/RNBQKBNR w KQkq - 0 1")

    # :binbo.new_game(pid)
    {_, fen} = :binbo.get_fen(pid)

    dests =
      case :binbo.all_legal_moves(pid, :str) do
        {:error, reason} -> raise reason
        {:ok, movelist} -> movelist
      end

    {clock_pid, white_time_ms, black_time_ms} =
      with :real_time <- config.time_control do
        case Dojo.Clock.start_link(%{minutes: config.minutes, increment: config.increment}) do
          {:error, reason} -> raise reason
          {:ok, pid} -> {pid, config.minutes * 60 * 1000, config.minutes * 60 * 1000}
        end
      else
        _ -> {nil, nil, nil}
      end

    {:ok,
     %Game{
       board_pid: pid,
       color: config.color,
       fen: fen,
       dests: dests,
       halfmove_clock: 0,
       time_control: config.time_control,
       minutes: config.minutes,
       increment: config.increment,
       clock_pid: clock_pid,
       white_time_ms: white_time_ms,
       black_time_ms: black_time_ms,
       difficulty: config.difficulty,
       status: :continue
     }}
  end

  @impl true
  def handle_call({:make_move, move}, _from, state) do
    case :binbo.move(state.board_pid, move) do
      {:error, reason} ->
        {:reply, {:error, reason}, state}

      {:ok, game_status} ->
        {_, fen} = :binbo.get_fen(state.board_pid)

        halfmove_clock = state.halfmove_clock + 1

        state =
          case state.time_control do
            :real_time ->
              cond do
                game_status != :continue ->
                  Dojo.Clock.stop_clock(state.clock_pid)
                  clock_state = Dojo.Clock.get_clock_state(state.clock_pid)
                  state = Map.replace(state, :white_time_ms, clock_state.white_time_milli)
                  state = Map.replace(state, :black_time_ms, clock_state.black_time_milli)
                  state

                halfmove_clock > 2 ->
                  Dojo.Clock.add_increment(state.clock_pid)
                  Dojo.Clock.switch_turn_color(state.clock_pid)
                  clock_state = Dojo.Clock.get_clock_state(state.clock_pid)
                  state = Map.replace(state, :white_time_ms, clock_state.white_time_milli)
                  state = Map.replace(state, :black_time_ms, clock_state.black_time_milli)
                  state

                halfmove_clock == 2 ->
                  Dojo.Clock.start_clock(state.clock_pid)
                  state = Map.replace(state, :white_time_ms, state.minutes * 60 * 1000)
                  state = Map.replace(state, :black_time_ms, state.minutes * 60 * 1000)
                  state

                true ->
                  state
              end

            _ ->
              state
          end

        dests =
          case :binbo.all_legal_moves(state.board_pid, :str) do
            {:error, reason} -> raise reason
            {:ok, movelist} -> movelist
          end

        state = Map.replace(state, :fen, fen)
        state = Map.replace(state, :dests, dests)
        state = Map.replace(state, :halfmove_clock, halfmove_clock)

        # set game status to :done if game is over
        state =
          if game_status == :continue do
            state
          else
            # TODO: Dojo.Clock.stop_clock(state.clock_pid)
            Map.replace(state, :status, game_status)
          end

        {:reply, {:ok, game_status}, state}

        # state = Map.replace(state, :status, :done)
    end
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
  def handle_call(:get_clock_pid, _from, state) do
    {:reply, state.clock_pid, state}
  end

  @impl true
  def handle_call(:get_all_legal_moves, _from, state) do
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

  @impl true
  def handle_call(:get_game_status, _from, state) do
    status =
      case :binbo.game_status(state.board_pid) do
        {:ok, status} -> status
        {:error, reason} -> raise reason
      end

    {:reply, status, state}
  end

  @impl true
  def handle_call({:resign, winning_color}, _from, state) do
    :binbo.set_game_winner(state.board_pid, winning_color, :resignation)

    state =
      if state.time_control == :real_time do
        Dojo.Clock.stop_clock(state.clock_pid)
        clock_state = Dojo.Clock.get_clock_state(state.clock_pid)
        state = Map.replace(state, :white_time_ms, clock_state.white_time_milli)
        state = Map.replace(state, :black_time_ms, clock_state.black_time_milli)
        state
      end

    status =
      case :binbo.game_status(state.board_pid) do
        {:ok, status} -> status
        {:error, reason} -> raise reason
      end

    state = Map.replace(state, :status, status)
    {:reply, :ok, state}
  end
end
