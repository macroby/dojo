defmodule DojoWeb.CancelController do
  use DojoWeb, :controller

  def cancel_game(conn, _) do
    text(conn, "cancel_game")
  end
end
