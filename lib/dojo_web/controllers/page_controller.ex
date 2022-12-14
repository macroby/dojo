defmodule DojoWeb.PageController do
  use DojoWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", layout: {DojoWeb.LayoutView, "home.html"})
  end

  def room(conn, %{"gameid" => gameid}) do
    Registry.lookup(GameRegistry, gameid)|> case do
      [] ->
        info = gameid
        render(conn, "room_error.html", info: info)
      [{pid, _}] ->
        fen = Dojo.Game.get_fen(pid)
        render(conn, "room.html", layout: {DojoWeb.LayoutView, "app.html"}, fen: fen)
    end
  end



  # see: github.com/dwyl/ping
  @spec ping(Plug.Conn.t(), any) :: Plug.Conn.t()
  def ping(conn, params) do
    Ping.render_pixel(conn, params)
  end
end
