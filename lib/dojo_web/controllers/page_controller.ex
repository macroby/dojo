defmodule DojoWeb.PageController do
  alias Phoenix.Token
  use DojoWeb, :controller
  require Logger

  @spec index(Plug.Conn.t(), any) :: Plug.Conn.t()
  def index(conn, _params) do
    conn =
      Plug.Conn.put_resp_header(
        conn,
        "cache-control",
        "no-cache, no-store, must-revalidate"
      )

    case get_session(conn, :user_token) do
      nil ->
        user_id = UUID.string_to_binary!(UUID.uuid1())
        user_id = Base.url_encode64(user_id, padding: false)

        token = Token.sign(conn, "user auth", user_id)
        conn = put_session(conn, :user_token, token)

        render(conn, "home.html",
          layout: {DojoWeb.LayoutView, "home_layout.html"},
          user_token: token
        )

      user_token ->
        render(conn, "home.html",
          layout: {DojoWeb.LayoutView, "home_layout.html"},
          user_token: user_token
        )
    end
  end

  def room(conn, %{"gameid" => gameid}) do
    cookie = get_session(conn, :user_token)

    case Token.verify(conn, "user auth", cookie, max_age: 60 * 60 * 24 * 365) do
      {:ok, _} ->
        Registry.lookup(GameRegistry, gameid)
        |> case do
          [] ->
            info = gameid
            render(conn, "room_error.html", info: info)

          [{pid, _}] ->
            game_info = Dojo.Game.get_state(pid)

            conn =
              Plug.Conn.put_resp_header(
                conn,
                "cache-control",
                "no-cache, no-store, must-revalidate"
              )

            {white_time_ms, black_time_ms} =
              case game_info.time_control do
                :real_time ->
                  clock_state = Dojo.Clock.get_clock_state(game_info.clock_pid)
                  white_time_ms = clock_state.white_time_milli
                  black_time_ms = clock_state.black_time_milli
                  {white_time_ms, black_time_ms}

                _ ->
                  {nil, nil}
              end

            # Dojo.Clock.get_clock_state(game_info.clock_pid)

            game_status =
              case game_info.status do
                :continue -> "continue"
                {_, _, _} -> Atom.to_string(elem(game_info.status, 1))
                {_, _} -> Enum.map(Tuple.to_list(game_info.status), fn x -> Atom.to_string(x) end)
              end

            render(conn, "room.html",
              layout: {DojoWeb.LayoutView, "room_layout.html"},
              fen: game_info.fen,
              color: game_info.color,
              minutes: game_info.minutes,
              increment: game_info.increment,
              dests: DojoWeb.Util.repack_dests(game_info.dests) |> Jason.encode!([]),
              white_clock: white_time_ms,
              black_clock: black_time_ms,
              user_token: cookie,
              game_status: game_status
            )
        end

      {:error, _} ->
        render(conn, "room_error.html",
          layout: {DojoWeb.LayoutView, "room_layout.html"},
          info: "Can't view other people's games for now..."
        )
    end
  end
end
