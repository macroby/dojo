defmodule DojoWeb.RoomChannel do
  alias Dojo.Game
  use DojoWeb, :channel
  require Logger

  @impl true
  def join("room:" <> _room_id, _payload, socket) do
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

  # Handle a resignation message
  @impl true
  def handle_in("resign", _payload, socket) do
    [_ | subtopic] = String.split(socket.topic, ":", parts: 2)
    gameid = List.first(subtopic)

    with [{pid, _}] <- Registry.lookup(GameRegistry, gameid),
         :continue <- Game.get_game_status(pid) do
      winner =
        case Game.get_side_to_move(pid) do
          :white -> :black
          :black -> :white
        end

      Game.resign(pid, winner)

      end_data_payload = %{
        "winner" => winner,
        "reason" => "resignation"
      }

      broadcast(socket, "endData", end_data_payload)
    end

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
              {:error, _reason} ->
                {:noreply, socket}

              {:ok, _} ->
                push(socket, "ack", %{})
                state = Game.get_state(pid)
                fen = state.fen

                side_to_move =
                  case state.halfmove_clock |> rem(2) do
                    0 -> :white
                    1 -> :black
                  end

                dests = Game.get_all_legal_moves(pid)
                dests = DojoWeb.Util.repack_dests(dests)

                payload =
                  Map.put(payload, :fen, fen)
                  |> Map.put(:halfmove_clock, state.halfmove_clock)
                  |> Map.put(:side_to_move, side_to_move)
                  |> Map.put(:white_clock, state.white_time_ms)
                  |> Map.put(:black_clock, state.black_time_ms)
                  |> Map.put(:dests, dests)

                broadcast(socket, "move", payload)

                if state.status == :continue do
                  case state.game_type do
                    :friend -> nil
                    :ai -> Task.start(fn -> ai_move(pid, state, socket) end)
                  end
                else
                  {winner, reason} =
                    case state.status do
                      {:checkmate, _} ->
                        case elem(state.status, 1) do
                          :white_wins -> {:white, "checkmate"}
                          :black_wins -> {:black, "checkmate"}
                        end

                      {:draw, _} ->
                        {:draw, "draw"}

                      {:winner, winner, {_, reason}} ->
                        {winner, reason}
                    end

                  broadcast(socket, "endData", %{
                    "winner" => winner,
                    "reason" => reason
                  })
                end

                {:noreply, socket}
            end
        end
    end
  end

  intercept(["move"])

  @impl true
  def handle_out("move", payload, socket) do
    [_ | subtopic] = String.split(socket.topic, ":", parts: 2)
    gameid = List.first(subtopic)

    with [{pid, _}] <- Registry.lookup(GameRegistry, gameid) do
      game_state = Game.get_state(pid)
      user_id = socket.assigns.user_id

      case {game_state.white_user_id == user_id, game_state.black_user_id == user_id} do
        {true, false} ->
          case payload.side_to_move do
            :black -> push(socket, "move", Map.delete(payload, :dests))
            :white -> push(socket, "move", payload)
          end

        {false, true} ->
          case payload.side_to_move do
            :white -> push(socket, "move", Map.delete(payload, :dests))
            :black -> push(socket, "move", payload)
          end

        {false, false} ->
          raise "user id stored in socket should match at least one of the players"

        {true, true} ->
          raise "user id stored in socket should match at most one of the players"
      end
    end

    {:noreply, socket}
  end

  def ai_move(pid, state, socket) do
    ai_move = get_ai_move(Dojo.Game.get_fen(pid), state.difficulty)
    Game.make_move(pid, ai_move)
    state = Game.get_state(pid)
    halfmove_clock = state.halfmove_clock
    fen = state.fen

    side_to_move =
      case state.halfmove_clock |> rem(2) do
        0 -> :white
        1 -> :black
      end

    movelist = Game.get_all_legal_moves(pid)
    dests = DojoWeb.Util.repack_dests(movelist)

    payload = %{}

    payload =
      Map.put(payload, :fen, fen)
      |> Map.put(:move, ai_move)
      |> Map.put(:side_to_move, side_to_move)
      |> Map.put(:dests, dests)
      |> Map.put(:halfmove_clock, halfmove_clock)
      |> Map.put(:white_clock, state.white_time_ms)
      |> Map.put(:black_clock, state.black_time_ms)

    broadcast(socket, "move", payload)

    if state.status != :continue do
      {winner, reason} =
        case state.status do
          {:checkmate, _} ->
            case elem(state.status, 1) do
              :white_wins -> {:white, "checkmate"}
              :black_wins -> {:black, "checkmate"}
            end

          {:draw, _} ->
            {:draw, "draw"}

          {:winner, winner, {_, reason}} ->
            {winner, reason}
        end

      broadcast(socket, "endData", %{
        "winner" => winner,
        "reason" => reason
      })
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

  def get_ai_move(fen, difficulty) do
    Registry.lookup(StockfishRegistry, <<"1">>)
    |> case do
      [] ->
        raise "Stockfish process not found"

      [{stockfish_pid, _}] ->
        Logger.debug("Stockfish difficulty: #{difficulty}")

        ai_move =
          Dojo.Stockfish.find_best_move(
            stockfish_pid,
            fen,
            difficulty
          )

        ai_move
    end
  end
end
