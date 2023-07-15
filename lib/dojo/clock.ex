defmodule Dojo.Clock do
  use GenServer
  require Logger

  def start_link(config) do
    GenServer.start_link(__MODULE__, config)
  end

  def start_clock(clock_pid) do
    GenServer.call(clock_pid, :start_clock)
  end

  def stop_clock(clock_pid) do
    GenServer.call(clock_pid, :stop_clock)
  end

  def get_clock_state(clock_pid) do
    GenServer.call(clock_pid, :get_clock_state)
  end

  def get_turn_color(clock_pid) do
    GenServer.call(clock_pid, :get_turn_color)
  end

  def switch_turn_color(clock_pid) do
    GenServer.call(clock_pid, :switch_turn_color)
  end

  def add_increment(clock_pid) do
    GenServer.call(clock_pid, :add_increment)
  end

  def stop_server(p_name) do
    GenServer.stop(p_name)
  end

  #######################
  # Server Implemention #
  #######################

  @impl true
  def init(%{minutes: minutes, increment: increment, game_pid: game_pid}) do
    white_time_milli = minutes * 60 * 1000

    black_time_milli = minutes * 60 * 1000

    {:ok,
     %{
       turn_color: :white,
       minutes: minutes,
       increment: increment,
       white_time_milli: white_time_milli,
       black_time_milli: black_time_milli,
       tref: nil,
       tick_time: nil,
       game_pid: game_pid
     }}
  end

  @impl true
  def handle_call(:start_clock, _from, state) do
    tick_time = :os.system_time(:milli_seconds)
    {_, tref} = :timer.send_interval(10, self(), :tick)
    state = %{state | tref: tref}
    state = %{state | tick_time: tick_time}

    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:stop_clock, _from, state) do
    :timer.cancel(state.tref)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:get_clock_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call(:get_turn_color, _from, state) do
    {:reply, state.turn_color, state}
  end

  @impl true
  def handle_call(:add_increment, _from, state) do
    state =
      case state.turn_color do
        :white ->
          white_time_milli = state.white_time_milli + state.increment * 1000
          %{state | white_time_milli: white_time_milli}

        :black ->
          black_time_milli = state.black_time_milli + state.increment * 1000
          %{state | black_time_milli: black_time_milli}
      end

    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:switch_turn_color, _from, state) do
    state =
      case state.turn_color do
        :white ->
          tick_time = :os.system_time(:milli_seconds)
          state = %{state | turn_color: :black}
          state = %{state | tick_time: tick_time}
          state

        :black ->
          tick_time = :os.system_time(:milli_seconds)
          state = %{state | turn_color: :white}
          state = %{state | tick_time: tick_time}
          state
      end

    {:reply, :ok, state}
  end

  @impl true
  def handle_info(:tick, state) when state.tick_time != nil do
    state =
      case state.turn_color do
        :white ->
          cond do
            state.white_time_milli <= 0 ->
              :timer.cancel(state.tref)
              Dojo.Game.zero_clock(state.game_pid, :black, state)
              state

            state.white_time_milli > 0 ->
              new_tick_time = :os.system_time(:milli_seconds)
              interval = new_tick_time - state.tick_time
              white_time_milli = state.white_time_milli - interval
              state = %{state | white_time_milli: white_time_milli}
              state = %{state | tick_time: new_tick_time}
              state
          end

        :black ->
          cond do
            state.black_time_milli <= 0 ->
              :timer.cancel(state.tref)
              Dojo.Game.zero_clock(state.game_pid, :white, state)
              state

            state.black_time_milli > 0 ->
              new_tick_time = :os.system_time(:milli_seconds)
              interval = new_tick_time - state.tick_time
              black_time_milli = state.black_time_milli - interval
              state = %{state | black_time_milli: black_time_milli}
              state = %{state | tick_time: new_tick_time}
              state
          end
      end

    {:noreply, state}
  end
end
