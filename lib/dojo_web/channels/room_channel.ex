defmodule DojoWeb.RoomChannel do
  alias Dojo.Game
  use DojoWeb, :channel

  @impl true
  def join("room:" <> room_id, _payload, socket) do
    # if authorized?(payload) do
      send(self(), :after_join)
      {:ok, socket}
    # else
    #   {:error, %{reason: "unauthorized"}}
    # end
  end

  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("shout", payload, socket) do
    Dojo.Message.changeset(%Dojo.Message{}, payload) |> Dojo.Repo.insert()
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_in("move", payload, socket) do
    [_ | subtopic] = String.split(socket.topic, ":", parts: 2)
    gameid = List.first(subtopic)
    Registry.lookup(GameRegistry, gameid)
    |> case do
      [] ->
        raise "this room doesnt exist"
      [{pid, _}] ->
        payload["move"] |> case do
          nil -> raise "couldnt get move from payload"
          move ->
            fen = Game.make_move(pid, move)
            payload = Map.put(payload, :fen, fen)
            broadcast(socket, "move", payload)
            {:noreply, socket}
        end
    end
  end

  # Add authorization logic here as required.
  # Auth coming soon via: https://github.com/dwyl/phoenix-chat-example/issues/54
  # defp authorized?(_payload) do
  #   true
  # end

  @impl true
  def handle_info(:after_join, socket) do
    Dojo.Message.get_messages()
    |> Enum.reverse()
    |> Enum.each(fn msg ->
      push(socket, "shout", %{
        name: msg.name,
        message: msg.message
      })
    end)

    # :noreply
    {:noreply, socket}
  end

end
