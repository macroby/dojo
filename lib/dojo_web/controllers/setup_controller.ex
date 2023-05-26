defmodule DojoWeb.SetupController do
  alias Dojo.Game
  alias Dojo.Stockfish
  use DojoWeb, :controller
  require Logger

  def setup_friend(conn, %{
        "color" => color,
        "time-control" => time_control
      })
      when time_control == "unlimited" do
    game_id = UUID.string_to_binary!(UUID.uuid1())
    game_id = Base.url_encode64(game_id, padding: false)

    game_init_state = %Game{
      game_id: game_id,
      color: color,
      time_control: time_control
    }

    GameSupervisor.create_game(game_init_state)
    |> case do
      {nil, error} -> raise error
      pid -> pid
    end

    conn = put_session(conn, :game_type, "friend")

    # redirect(conn, to: Routes.page_path(conn, :room, game_id))
    text(conn, "#{game_id}")
  end

  def setup_friend(conn, %{
        "color" => color,
        "time-control" => time_control,
        "minutes" => minutes,
        "increment" => increment
      })
      when time_control == "real time" do
    text(conn, "#{color}, #{time_control}, #{minutes}, #{increment}")
  end

  def setup_ai(conn, %{
        "color" => color,
        "time-control" => time_control,
        "minutes" => minutes,
        "increment" => increment,
        "difficulty" => difficulty
      })
      when time_control == "real time" do
    color =
      case color do
        "white" ->
          "white"

        "black" ->
          "black"

        _ ->
          case :rand.uniform(10) do
            x when x > 5 -> "white"
            _ -> "black"
          end
      end

    time_control =
      case time_control do
        "unlimited" -> :unlimited
        "real time" -> :real_time
        "correspondence" -> :correspondence
        _ -> :unlimited
      end

    minutes =
      case minutes do
        "5" -> 5
        "10" -> 10
        "15" -> 15
        "30" -> 30
        _ -> 5
      end

    increment =
      case increment do
        "0" -> 0
        "3" -> 3
        "5" -> 5
        "10" -> 10
        "20" -> 20
        _ -> 0
      end

    difficulty =
      case difficulty do
        "1" -> 1
        "2" -> 2
        "3" -> 3
        "4" -> 4
        "5" -> 5
        "6" -> 6
        "7" -> 7
        "8" -> 8
        _ -> 1
      end

    game_id = UUID.string_to_binary!(UUID.uuid1())
    game_id = Base.url_encode64(game_id, padding: false)

    game_init_state = %Game{
      game_id: game_id,
      color: color,
      time_control: time_control,
      minutes: minutes,
      increment: increment,
      difficulty: difficulty
    }

    pid =
      GameSupervisor.create_game(game_init_state)
      |> case do
        {nil, error} -> raise error
        pid -> pid
      end

    Logger.debug("Stockfish count: #{Registry.count(StockfishRegistry)}")

    if Dojo.Game.get_halfmove_clock(pid) == 0 && color == "black" do
      # Dojo.Game.make_move(pid, <<"e2e4">>)
      Registry.lookup(StockfishRegistry, <<"1">>)
      |> case do
        [] ->
          raise "Stockfish process not found"

        [{stockfish_pid, _}] ->
          ai_move = Stockfish.find_best_move(stockfish_pid, Dojo.Game.get_fen(pid), difficulty)
          Dojo.Game.make_move(pid, ai_move)
      end
    end

    redirect(conn, to: Routes.page_path(conn, :room, game_id))
  end

  def setup_ai(conn, %{
        "color" => color,
        "time-control" => time_control,
        "difficulty" => difficulty
      })
      when time_control == "unlimited" do
    color =
      case color do
        "white" ->
          "white"

        "black" ->
          "black"

        _ ->
          case :rand.uniform(10) do
            x when x > 5 -> "white"
            _ -> "black"
          end
      end

    time_control =
      case time_control do
        "unlimited" -> :unlimited
        "real time" -> :real_time
        "correspondence" -> :correspondence
        _ -> :unlimited
      end

    difficulty =
      case difficulty do
        "1" -> 1
        "2" -> 2
        "3" -> 3
        "4" -> 4
        "5" -> 5
        "6" -> 6
        "7" -> 7
        "8" -> 8
        _ -> 1
      end

    game_id = UUID.string_to_binary!(UUID.uuid1())
    game_id = Base.url_encode64(game_id, padding: false)

    pid =
      GameSupervisor.create_game(%Game{
        game_id: game_id,
        color: color,
        time_control: time_control,
        difficulty: difficulty
      })
      |> case do
        {nil, error} -> raise error
        pid -> pid
      end

    Logger.debug("Stockfish count: #{Registry.count(StockfishRegistry)}")

    if Dojo.Game.get_halfmove_clock(pid) == 0 && color == "black" do
      # Dojo.Game.make_move(pid, <<"e2e4">>)
      Registry.lookup(StockfishRegistry, <<"1">>)
      |> case do
        [] ->
          raise "Stockfish process not found"

        [{stockfish_pid, _}] ->
          ai_move = Stockfish.find_best_move(stockfish_pid, Dojo.Game.get_fen(pid), difficulty)
          Dojo.Game.make_move(pid, ai_move)
      end
    end

    redirect(conn, to: Routes.page_path(conn, :room, game_id))
  end
end
