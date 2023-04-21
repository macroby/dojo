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
        game_info = Dojo.Game.get_state(pid)

        conn =
          Plug.Conn.put_resp_header(conn, "cache-control", "no-cache, no-store, must-revalidate")

        clock_state = Dojo.Clock.get_clock_state(game_info.clock_pid)

        render(conn, "room.html",
          layout: {DojoWeb.LayoutView, "room_layout.html"},
          fen: game_info.fen,
          color: game_info.color,
          time_control: game_info.time_control,
          increment: game_info.increment,
          dests: DojoWeb.Util.repack_dests(game_info.dests) |> Jason.encode!([]),
          white_clock: clock_state.white_time_milli,
          black_clock: clock_state.black_time_milli
        )
    end
  end
end
