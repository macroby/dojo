defmodule DojoWeb.PageController do
  use DojoWeb, :controller
  require Logger

  @spec index(Plug.Conn.t(), any) :: Plug.Conn.t()
  def index(conn, _params) do
    render(conn, "home.html", layout: {DojoWeb.LayoutView, "home_layout.html"})
  end

  def room(conn, %{"gameid" => gameid}) do
    Registry.lookup(GameRegistry, gameid)
    |> case do
      [] ->
        info = gameid
        render(conn, "room_error.html", info: info)

      [{pid, _}] ->
        game_info = Dojo.Game.get_info(pid)
        render(conn, "room.html",
          layout: {DojoWeb.LayoutView, "room_layout.html"},
          fen: game_info.fen,
          color: game_info.color,
          dests: repack_dests(game_info.dests)
        )
    end
  end

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

  # see: github.com/dwyl/ping
  @spec ping(Plug.Conn.t(), any) :: Plug.Conn.t()
  def ping(conn, params) do
    Ping.render_pixel(conn, params)
  end
end
