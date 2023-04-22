defmodule DojoWeb.RoomChannel do
  alias Dojo.Game
  use DojoWeb, :channel
  require Logger

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
    push(socket, "pong", payload)
    {:noreply, socket}
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
        payload["move"]
        |> case do
          nil ->
            raise "couldnt get move from payload"

          move ->
            case Game.make_move(pid, move) do
              # TODO: actually handle faulty move instead of just raising
              {:error, reason} -> raise reason
              {:ok, _} -> push(socket, "ack", %{})
            end

            state = Game.get_state(pid)
            fen = state.fen
            side_to_move = Game.get_side_to_move(pid)
            clock_state = Dojo.Clock.get_clock_state(state.clock_pid)

            payload =
              Map.put(payload, :fen, fen)
              |> Map.put(:halfmove_clock, state.halfmove_clock)
              |> Map.put(:side_to_move, side_to_move)
              |> Map.put(:white_clock, clock_state.white_time_milli)
              |> Map.put(:black_clock, clock_state.black_time_milli)

            broadcast(socket, "move", payload)
            # clock_state = Dojo.Clock.get_clock_state(state.clock_pid)
            # payload = Map.put(payload, :white_clock, clock_state.white_time_milli)
            # payload = Map.put(payload, :black_clock, clock_state.black_time_milli)

            # Im gonna stick the ai logic right here for now,
            # but i forsee some refactoring in the future
            # Using bin version to play nicely with concat

            movelist = Game.get_all_legal_moves(pid)
            movelist_length = length(movelist)
            # Process.sleep(5000)
            if movelist_length > 0 do
              ai_move =
                Registry.lookup(StockfishRegistry, <<"1">>)
                |> case do
                  [] ->
                    raise "Stockfish process not found"

                  [{stockfish_pid, _}] ->
                    Logger.error("Stockfish difficulty: #{state.difficulty}")

                    ai_move =
                      Dojo.Stockfish.find_best_move(
                        stockfish_pid,
                        Dojo.Game.get_fen(pid),
                        state.difficulty
                      )

                    Game.make_move(pid, ai_move)
                    ai_move
                end

              state = Game.get_state(pid)
              halfmove_clock = state.halfmove_clock
              fen = state.fen
              side_to_move = Game.get_side_to_move(pid)
              movelist = Game.get_all_legal_moves(pid)
              dests = DojoWeb.Util.repack_dests(movelist)
              clock_state = Dojo.Clock.get_clock_state(state.clock_pid)

              payload = %{}

              payload =
                Map.put(payload, :fen, fen)
                |> Map.put(:move, ai_move)
                |> Map.put(:side_to_move, side_to_move)
                |> Map.put(:dests, dests)
                |> Map.put(:halfmove_clock, halfmove_clock)
                |> Map.put(:white_clock, clock_state.white_time_milli)
                |> Map.put(:black_clock, clock_state.black_time_milli)

              broadcast(socket, "move", payload)
            end

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
    push(socket, "start_ping", %{})

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
