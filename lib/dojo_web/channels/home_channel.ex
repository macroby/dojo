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
      Dojo.Game.cancel(pid, payload["game_id"])
      Dojo.Game.stop(pid)
      Dojo.GameTracker.remove_open_game(payload["game_id"])
      Dojo.UserTracker.remove_active_user(socket.assigns.user_id)
      DojoWeb.Endpoint.broadcast("home:lobby", "closed_game", payload)
    end

    {:noreply, socket}
  end

  # Add authorization logic here as required.
  # defp authorized?(_payload) do
  #   true
  # end
end
