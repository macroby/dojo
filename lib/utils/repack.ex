defmodule DojoWeb.Util do
  @doc """
  Dinbo moveset -> chessground moveset

  dinbo moveset stores every possible move
  as its own element, while chessground uses
  a moveset that stores each possible starting
  square along with all of it possible destinations
  into one element.

  [a2, a3], [a2, a4], [b2, b3], [b2, b4]...

  to

  [a2, [a3, a4]], [b2, [b3, b4]]...

  """
  def repack_dests(dests) do
    Enum.chunk_by(dests, fn {x, _} -> x end)
    |> Enum.map(fn x ->
      [head | _] = x
      head = elem(head, 0)

      dests =
        Enum.map(x, fn {_, dest} ->
          dest
        end)

      [head, dests]
    end)
    |> Map.new(fn [head | tail] ->
      tail = List.first(tail)
      tail = Enum.map(tail, fn x -> List.to_string(x) end)
      {head, tail}
    end)
    |> Jason.encode!([])
  end
end
