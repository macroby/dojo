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

  #######################
  # Server Implemention #
  #######################

  @impl true
  def init(%{time_control: time_control, increment: increment}) do
    white_time_milli = time_control * 60 * 1000

    black_time_milli = time_control * 60 * 1000

    {:ok,
     %{
       turn_color: :white,
       time_control: time_control,
       increment: increment,
       white_time_milli: white_time_milli,
       black_time_milli: black_time_milli,
       tref: nil
     }}
  end

  @impl true
  def handle_call(:start_clock, _from, state) do
    {_, tref} = :timer.send_interval(10, self(), :tick)
    state = %{state | tref: tref}
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
          %{state | turn_color: :black}

        :black ->
          %{state | turn_color: :white}
      end

    {:reply, :ok, state}
  end

  @impl true
  def handle_info(:tick, state) do
    state =
      case state.turn_color do
        :white ->
          cond do
            state.white_time_milli == 0 ->
              state

            state.white_time_milli > 0 ->
              white_time_milli = state.white_time_milli - 10
              %{state | white_time_milli: white_time_milli}
          end

        :black ->
          cond do
            state.black_time_milli == 0 ->
              state

            state.black_time_milli > 0 ->
              black_time_milli = state.black_time_milli - 10
              %{state | black_time_milli: black_time_milli}
          end
      end

    {:noreply, state}
  end
end
