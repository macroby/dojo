defmodule Dojo.GameState do
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
end
