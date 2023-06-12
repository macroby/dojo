defmodule Dojo.GameSupervisor do
  alias Dojo.Game
  alias Dojo.GameState
  use DynamicSupervisor
  require Logger

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_game(game = %GameState{}) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Game, game}
    )
    |> case do
      {:error, {:already_started, pid}} -> pid
      {:error, reason} -> raise reason
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
