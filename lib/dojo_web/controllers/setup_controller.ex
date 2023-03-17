defmodule DojoWeb.SetupController do
  use DojoWeb, :controller

  def setup_ai(conn, %{"color" => color, "time-control" => time_control, "increment" => increment}) do
    color = case color do
      "white" -> "white"
      "black" -> "black"
      _ ->
        case :rand.uniform(10) do
          x when x > 5 -> "white"
          _ -> "black"
        end
    end

    time_control = case time_control do
      "5" -> 5
      "10" -> 10
      "15" -> 15
      "30" -> 30
      _ -> 5
    end

    increment = case increment do
      "0" -> 0
      "3" -> 3
      "5" -> 5
      "10" -> 10
      "20" -> 20
      _ -> 0
    end

    id = UUID.string_to_binary!(UUID.uuid1())
    id = Base.url_encode64(id, padding: false)
    GameSupervisor.create_game(id, color, time_control, increment) |> case do
      {nil, error} -> raise error
      _ -> nil
    end
    redirect(conn, to: Routes.page_path(conn, :room, id))
  end
end
