defmodule DojoWeb.SetupController do
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
    GameSupervisor.create_game(game_id, color, :unlimited)
    # pid =
    #   GameSupervisor.create_game(game_id, color, :unlimited)
    #   |> case do
    #     {nil, error} -> raise error
    #     pid -> pid
    #   end
    text(conn, "#{color}, #{time_control}")
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

  def setup_friend(conn, %{
        "color" => color,
        "time-control" => time_control,
        "days" => days
      })
      when time_control == "correspondence" do
    text(conn, "#{color}, #{time_control}, #{days}")
  end

  def setup_ai(conn, %{
        "color" => color,
        "minutes" => minutes,
        "increment" => increment,
        "difficulty" => difficulty
      }) do
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

    pid =
      GameSupervisor.create_game(game_id, color, minutes, increment, difficulty)
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
