defmodule DojoWeb.SetupController do
  use DojoWeb, :controller

  def setup_ai(conn, _params) do
    GameSupervisor.create_game()
    id = :rand.uniform(5000)
    redirect(conn, to: "/#{id}")
  end
end
