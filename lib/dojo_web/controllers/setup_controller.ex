defmodule DojoWeb.SetupController do
  use DojoWeb, :controller

  def setup_ai(conn, %{"color" => color}) do
    color = case color do
      "white" -> {}
      "black" -> {}
      _ ->
        case :rand.uniform(10) do
          x when x > 5 -> "white"
          _ -> "black"
        end
    end
    id = UUID.string_to_binary!(UUID.uuid1())
    id = Base.url_encode64(id, padding: false)
    GameSupervisor.create_game(id) |> case do
      {nil, error} -> raise error
      _ -> nil
    end
    redirect(conn, to: Routes.page_path(conn, :room, id))
  end
end
