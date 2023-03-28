defmodule Dojo.Clock do
  use GenServer
  require Logger

  def start_link(config) do
    GenServer.start_link(__MODULE__, config)
  end

  def start_clock(clock_pid) do
    GenServer.call(clock_pid, :start_clock)
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

  #######################
  # Server Implemention #
  #######################

  @impl true
  def init(%{time_control: time_control, increment: increment}) do
    white_time_seconds = time_control * 60
    white_time_hundredths = 0

    black_time_seconds = time_control * 60
    black_time_hundredths = 0

    {:ok,
     %{
       turn_color: :white,
       time_control: time_control,
       increment: increment,
       white_time_seconds: white_time_seconds,
       white_time_hundredths: white_time_hundredths,
       black_time_seconds: black_time_seconds,
       black_time_hundredths: black_time_hundredths
     }}
  end

  @impl true
  def handle_call(:start_clock, _from, state) do
    :timer.send_interval(10, self(), :tick)
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
            state.white_time_hundredths == 0 && state.white_time_seconds > 0 ->
              white_time_seconds = state.white_time_seconds - 1
              white_time_hundredths = 99

              %{
                state
                | white_time_seconds: white_time_seconds,
                  white_time_hundredths: white_time_hundredths
              }

            state.white_time_hundredths > 0 ->
              white_time_seconds = state.white_time_seconds
              white_time_hundredths = state.white_time_hundredths - 1

              %{
                state
                | white_time_seconds: white_time_seconds,
                  white_time_hundredths: white_time_hundredths
              }

            true ->
              state
          end

        :black ->
          cond do
            state.black_time_hundredths == 0 && state.black_time_seconds > 0 ->
              black_time_seconds = state.black_time_seconds - 1
              black_time_hundredths = 99

              %{
                state
                | black_time_seconds: black_time_seconds,
                  black_time_hundredths: black_time_hundredths
              }

            state.black_time_hundredths > 0 ->
              black_time_seconds = state.black_time_seconds
              black_time_hundredths = state.black_time_hundredths - 1

              %{
                state
                | black_time_seconds: black_time_seconds,
                  black_time_hundredths: black_time_hundredths
              }

            true ->
              state
          end
      end
    {:noreply, state}
  end
end
