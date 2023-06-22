defmodule DojoWeb.PageController do
  alias Phoenix.Token
  alias Dojo.Game
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

    {user_token, csrf_token, conn, user_id} =
      case get_session(conn, :user_token) do
        nil ->
          user_id = UUID.string_to_binary!(UUID.uuid1())
          user_id = Base.url_encode64(user_id, padding: false)

          token = Token.sign(conn, "user auth", user_id)
          conn = put_session(conn, :user_token, token)

          csrf_token = get_csrf_token()
          conn = put_resp_cookie(conn, "_csrf_token", csrf_token, http_only: false)

          {token, csrf_token, conn, user_id}

        user_token ->
          csrf_token = conn.cookies["_csrf_token"]

          user_id =
            case Token.verify(conn, "user auth", user_token) do
              {:ok, user_id} -> user_id
              _ -> raise "invalid user token"
            end

          {user_token, csrf_token, conn, user_id}
      end

    open_games =
      Map.to_list(Dojo.GameTracker.get_open_games())
      |> Enum.map(fn {game_id, game} ->
        game_creator_id =
          case {game.white_user_id, game.black_user_id} do
            {nil, nil} ->
              raise "Invalid game, both players are nil but a player is required to start a game."

            {white_user_id, nil} ->
              white_user_id

            {nil, black_user_id} ->
              black_user_id

            {_white_user_id, _black_user_id} ->
              raise "Invalid game, both players are not nil but only one player is required to start a game."
          end

        time_control = game.time_control

        {minutes, increment} =
          case time_control do
            :real_time -> {Integer.to_string(game.minutes), Integer.to_string(game.increment)}
            :unlimited -> {"inf", "inf"}
          end

        %{
          "game_id" => game_id,
          "game_creator_id" => game_creator_id,
          "minutes" => minutes,
          "increment" => increment
        }
      end)
      |> Jason.encode!()

    render(conn, "home.html",
      layout: {DojoWeb.LayoutView, "home_layout.html"},
      csrf_token: csrf_token,
      user_token: user_token,
      user_id: user_id,
      open_games: open_games
    )
  end

  def cancel(conn, %{"gameid" => game_id}) do
    with [{pid, _}] <- Registry.lookup(GameRegistry, game_id),
         true <- Game.get_halfmove_clock(pid) < 2 do
      user_id = Token.verify(conn, "user auth", get_session(conn, :user_token))
      Dojo.UserTracker.remove_active_user(user_id)
      Game.cancel(pid, game_id)
      DojoWeb.Endpoint.broadcast!("room:" <> game_id, "cancel", %{})
      redirect(conn, to: Routes.page_path(conn, :index))
    end
  end

  def accept(conn, %{"gameid" => game_id}) do
    case Registry.lookup(GameRegistry, game_id) do
      [] ->
        info = game_id
        render(conn, "room_error.html", info: info)

      [{pid, _}] ->
        game_state = Dojo.Game.get_state(pid)

        case game_state.invite_accepted do
          true ->
            render_room_error(conn)

          false ->
            user_token = get_session(conn, :user_token)

            user_id =
              case Token.verify(conn, "user auth", user_token) do
                {:ok, user_id} -> user_id
                _ -> raise "invalid user token"
              end

            case game_state.white_user_id == user_id or game_state.black_user_id == user_id do
              true ->
                render_room_error(conn)

              false ->
                case {game_state.white_user_id, game_state.black_user_id} do
                  {nil, nil} ->
                    raise "Game must have at least one player already in it"

                  {nil, _} ->
                    Dojo.Game.set_white_user_id(pid, user_id)

                  {_, nil} ->
                    Dojo.Game.set_black_user_id(pid, user_id)

                  _ ->
                    raise "Game already has two players"
                end

                Dojo.Game.accept_invite(pid)

                Dojo.UserTracker.add_active_user(user_id, pid)

                DojoWeb.Endpoint.broadcast!("room:" <> game_id, "invite_accepted", %{})

                redirect(conn, to: Routes.page_path(conn, :room, game_id))
            end

          _ ->
            "invite_accepted must be set as true or false for play-with-friend games"
        end
    end
  end

  def room(conn, %{"gameid" => url_game_id}) do
    pid =
      case Registry.lookup(GameRegistry, url_game_id) do
        [] ->
          render_room_error(conn)
          raise "Game not found"

        [{pid, _}] ->
          pid
      end

    game_state = Dojo.Game.get_state(pid)

    {conn, user_token} =
      case get_session(conn, :user_token) do
        nil ->
          user_id = UUID.string_to_binary!(UUID.uuid1())
          user_id = Base.url_encode64(user_id, padding: false)

          token = Token.sign(conn, "user auth", user_id)
          conn = put_session(conn, :user_token, token)
          {conn, token}

        user_token ->
          {conn, user_token}
      end

    conn = fetch_cookies(conn)

    case game_state.game_type do
      :friend ->
        handle_friend_room(conn, game_state, user_token)

      :ai ->
        handle_ai_room(conn, game_state, user_token)

      :open ->
        handle_open_room(conn, game_state, user_token)
    end
  end

  def handle_open_room(conn, game_state, user_token) do
    case Token.verify(conn, "user auth", user_token) do
      {:ok, user_id} ->
        case game_state.white_user_id == user_id or game_state.black_user_id == user_id do
          true ->
            conn =
              Plug.Conn.put_resp_header(
                conn,
                "cache-control",
                "no-cache, no-store, must-revalidate"
              )

            game_status =
              case game_state.status do
                :continue ->
                  "continue"

                {_, _, _} ->
                  Atom.to_string(elem(game_state.status, 1))

                {_, _} ->
                  Enum.map(Tuple.to_list(game_state.status), fn x -> Atom.to_string(x) end)
              end

            {white_time_ms, black_time_ms} =
              case game_state.time_control do
                :real_time ->
                  clock_state = Dojo.Clock.get_clock_state(game_state.clock_pid)
                  white_time_ms = clock_state.white_time_milli
                  black_time_ms = clock_state.black_time_milli
                  {white_time_ms, black_time_ms}

                _ ->
                  {nil, nil}
              end

            color =
              case {game_state.white_user_id == user_id, game_state.black_user_id == user_id} do
                {true, false} -> :white
                {false, true} -> :black
                _ -> raise "User is not a player in this game"
              end

            render(conn, "room.html",
              layout: {DojoWeb.LayoutView, "room_layout.html"},
              fen: game_state.fen,
              color: color,
              game_type: game_state.game_type,
              invite_accepted: game_state.invite_accepted,
              minutes: game_state.minutes,
              increment: game_state.increment,
              dests: DojoWeb.Util.repack_dests(game_state.dests) |> Jason.encode!([]),
              white_clock: white_time_ms,
              black_clock: black_time_ms,
              user_token: user_token,
              game_status: game_status
            )

          false ->
            redirect(conn, to: Routes.page_path(conn, :index))
        end
    end
  end

  def handle_friend_room(conn, game_state, user_token) do
    case game_state.invite_accepted do
      true ->
        case Token.verify(conn, "user auth", user_token) do
          {:ok, user_id} ->
            case game_state.white_user_id == user_id or game_state.black_user_id == user_id do
              true ->
                conn =
                  Plug.Conn.put_resp_header(
                    conn,
                    "cache-control",
                    "no-cache, no-store, must-revalidate"
                  )

                game_status =
                  case game_state.status do
                    :continue ->
                      "continue"

                    {_, _, _} ->
                      Atom.to_string(elem(game_state.status, 1))

                    {_, _} ->
                      Enum.map(Tuple.to_list(game_state.status), fn x -> Atom.to_string(x) end)
                  end

                {white_time_ms, black_time_ms} =
                  case game_state.time_control do
                    :real_time ->
                      clock_state = Dojo.Clock.get_clock_state(game_state.clock_pid)
                      white_time_ms = clock_state.white_time_milli
                      black_time_ms = clock_state.black_time_milli
                      {white_time_ms, black_time_ms}

                    _ ->
                      {nil, nil}
                  end

                color =
                  case {game_state.white_user_id == user_id, game_state.black_user_id == user_id} do
                    {true, false} -> :white
                    {false, true} -> :black
                    _ -> raise "User is not a player in this game"
                  end

                render(conn, "room.html",
                  layout: {DojoWeb.LayoutView, "room_layout.html"},
                  fen: game_state.fen,
                  color: color,
                  game_type: game_state.game_type,
                  invite_accepted: game_state.invite_accepted,
                  minutes: game_state.minutes,
                  increment: game_state.increment,
                  dests: DojoWeb.Util.repack_dests(game_state.dests) |> Jason.encode!([]),
                  white_clock: white_time_ms,
                  black_clock: black_time_ms,
                  user_token: user_token,
                  game_status: game_status
                )

              false ->
                Logger.error("user id: #{user_id}")

                raise "User is not a player in this game #{user_id} -- #{game_state.white_user_id} -- #{game_state.black_user_id}"
            end

          {:error, _} ->
            raise "invalid user token"
        end

      false ->
        case Token.verify(conn, "user auth", user_token) do
          {:ok, user_id} ->
            case game_state.white_user_id == user_id or game_state.black_user_id == user_id do
              true ->
                render(conn, "friend_pending.html",
                  layout: {DojoWeb.LayoutView, "friend_pending_layout.html"},
                  user_token: user_token,
                  game_id: game_state.game_id
                )

              false ->
                render(conn, "friend_invite.html",
                  layout: {DojoWeb.LayoutView, "friend_invite_layout.html"},
                  user_token: user_token,
                  game_id: game_state.game_id
                )
            end

          {:error, _} ->
            raise "invalid user token"
        end

      _ ->
        raise "invite_accepted must be set for play-with-friend games"
    end
  end

  def handle_ai_room(conn, game_state, user_token) do
    conn =
      Plug.Conn.put_resp_header(
        conn,
        "cache-control",
        "no-cache, no-store, must-revalidate"
      )

    {white_time_ms, black_time_ms} =
      case game_state.time_control do
        :real_time ->
          clock_state = Dojo.Clock.get_clock_state(game_state.clock_pid)
          white_time_ms = clock_state.white_time_milli
          black_time_ms = clock_state.black_time_milli
          {white_time_ms, black_time_ms}

        _ ->
          {nil, nil}
      end

    game_status =
      case game_state.status do
        :continue ->
          "continue"

        {_, _, _} ->
          Atom.to_string(elem(game_state.status, 1))

        {_, _} ->
          Enum.map(Tuple.to_list(game_state.status), fn x -> Atom.to_string(x) end)
      end

    render(conn, "room.html",
      layout: {DojoWeb.LayoutView, "room_layout.html"},
      fen: game_state.fen,
      color: game_state.color,
      game_type: game_state.game_type,
      invite_accepted: game_state.invite_accepted,
      minutes: game_state.minutes,
      increment: game_state.increment,
      dests: DojoWeb.Util.repack_dests(game_state.dests) |> Jason.encode!([]),
      white_clock: white_time_ms,
      black_clock: black_time_ms,
      game_status: game_status,
      user_token: user_token
    )
  end

  def render_room_error(conn) do
    render(conn, "room_error.html",
      layout: {DojoWeb.LayoutView, "room_layout.html"},
      info: "catastrophic disaster..."
    )
  end
end
