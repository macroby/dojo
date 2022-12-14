defmodule GameSupervisor do
  alias Dojo.Game
  use DynamicSupervisor

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def create_game(id) do
    DynamicSupervisor.start_child(__MODULE__, {Game, id}) |> case do
      {:error, {:already_started, pid}} -> pid
      {:error, _} -> raise "trouble starting game child"
      {:ok, pid} -> pid
    end
  end

  @spec close_game(pid) :: :ok | {:error, :not_found}
  def close_game(game_pid) do
    DynamicSupervisor.terminate_child(__MODULE__, game_pid)
  end

  def children do
    DynamicSupervisor.which_children(__MODULE__)
  end

  def count_childen do
    DynamicSupervisor.count_children(__MODULE__)
  end
end
