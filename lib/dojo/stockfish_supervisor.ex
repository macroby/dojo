defmodule StockfishSupervisor do
  alias Dojo.Stockfish
  use DynamicSupervisor

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def create_stockfish(id) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Stockfish, %{id: id}}
    )
    |> case do
      {:error, {:already_started, pid}} -> pid
      {:error, reason} -> raise reason
      {:ok, pid} -> pid
    end
  end

  @spec close_stockfish(pid) :: :ok | {:error, :not_found}
  def close_stockfish(stockfish_pid) do
    DynamicSupervisor.terminate_child(__MODULE__, stockfish_pid)
  end

  def children do
    DynamicSupervisor.which_children(__MODULE__)
  end

  def count_childen do
    DynamicSupervisor.count_children(__MODULE__)
  end
end
