defmodule DojoWeb.HomeChannel do
  use DojoWeb, :channel
  require Logger

  @impl true
  def join("home:lobby", _payload, socket) do
    {:ok, socket}
    # if authorized?(payload) do
    #   {:ok, socket}
    # else
    #   {:error, %{reason: "unauthorized"}}
    # end
  end

  @impl true
  def join("home:" <> _user_id, _payload, socket) do
    {:ok, socket}
    # if authorized?(payload) do
    #   {:ok, socket}
    # else
    #   {:error, %{reason: "unauthorized"}}
    # end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (home:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_in("cancel", payload, socket) do
    with [{pid, _}] <- Registry.lookup(GameRegistry, payload["game_id"]),
         true <- Dojo.Game.get_halfmove_clock(pid) < 2 do
      Dojo.Game.stop(pid)
      Dojo.GameTracker.remove_open_game(payload["game_id"])
      Dojo.UserTracker.remove_active_user(socket.assigns.user_id)
      DojoWeb.Endpoint.broadcast("home:lobby", "closed_game", payload)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_in("accept", payload, socket) do
    with [{pid, _}] <- Registry.lookup(GameRegistry, payload["game_id"]) do
      game_state = Dojo.Game.get_state(pid)
      user_id = socket.assigns.user_id

      case game_state.invite_accepted do
        false ->
          game_creator_id =
            case {game_state.white_user_id, game_state.black_user_id} do
              {nil, nil} ->
                raise "Game must have at least one player already in it"

              {nil, game_creator_id} ->
                Dojo.Game.set_white_user_id(pid, user_id)
                game_creator_id

              {game_creator_id, nil} ->
                Dojo.Game.set_black_user_id(pid, user_id)
                game_creator_id

              _ ->
                raise "Game already has two players"
            end

          Dojo.Game.accept_invite(pid)

          Dojo.GameTracker.remove_open_game(game_state.game_id)

          Dojo.UserTracker.add_active_user(user_id, pid)

          DojoWeb.Endpoint.broadcast!("home:" <> user_id, "redirect", %{
            "game_id" => game_state.game_id
          })

          DojoWeb.Endpoint.broadcast!("home:" <> game_creator_id, "redirect", %{
            "game_id" => game_state.game_id
          })

          DojoWeb.Endpoint.broadcast!("home:lobby", "closed_game", %{
            "game_id" => game_state.game_id
          })

        _ ->
          nil
      end
    end

    {:noreply, socket}
  end

  @impl true
  def terminate(_reason, socket) do
    case Dojo.UserTracker.get_active_user(socket.assigns.user_id) do
      nil ->
        nil

      active_user ->
        case socket.topic == "home:lobby" do
          false ->
            nil

          true ->
            game_id = Dojo.Game.get_game_id(active_user.game_pid)

            case Dojo.GameTracker.has_open_game(game_id) do
              false ->
                nil

              true ->
                Dojo.Game.stop(active_user.game_pid)
                Dojo.GameTracker.remove_open_game(game_id)
                Dojo.UserTracker.remove_active_user(socket.assigns.user_id)

                DojoWeb.Endpoint.broadcast("home:lobby", "closed_game", %{
                  "game_id" => game_id
                })
            end
        end
    end
  end
end
