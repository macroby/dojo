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
          dests: DojoWeb.Util.repack_dests(game_info.dests)
        )
    end
  end
end
