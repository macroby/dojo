defmodule DojoWeb.SetupController do
  use DojoWeb, :controller

  def setup_ai(conn, _params) do
    GameSupervisor.create_game()
    id = UUID.string_to_binary!(UUID.uuid1())
    id = Base.url_encode64(id)
    redirect(conn, to: "/#{id}")
  end
end
