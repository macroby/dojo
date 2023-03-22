defmodule Dojo.Clock do
  use GenServer
  # Process.send_after(self(), :tick, 1000)
  def init(%{time_control: time_control, increment: increment}) do
    white_time_seconds = String.to_integer(time_control) * 60
    white_time_hundredths = 0

    black_time_seconds = String.to_integer(time_control) * 60
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

  def handle_call(:start_clock, _from, state) do
    {_, tick_pid} = Task.start_link(fn -> tick() end)
    {:reply, :ok, %{state | tick_pid: tick_pid}}
  end

  def handle_call(:get_clock_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:get_white_time, _from, state) do
    {:reply, state.white_time, state}
  end

  def handle_call(:get_black_time, _from, state) do
    {:reply, state.black_time, state}
  end

  def handle_call(:get_turn_color, _from, state) do
    {:reply, state.turn_color, state}
  end

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
          nil
      end

    {:noreply, state}
  end

  defp tick() do
    Process.send_after(self(), :tick, 10)
    tick()
  end
end
