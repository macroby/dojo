defmodule DojoWeb.SetupController do
  use DojoWeb, :controller

  def setup_ai(conn, _params) do
    id = UUID.string_to_binary!(UUID.uuid1())
    id = Base.url_encode64(id, padding: false)
    GameSupervisor.create_game(id) |> case do
      {nil, error} -> raise error
      _ -> nil
    end
    redirect(conn, to: Routes.page_path(conn, :room, id))
  end
end
