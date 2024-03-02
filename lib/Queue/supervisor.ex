defmodule Dueue.Queue do
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      Dueue.Queue.Store,
      Dueue.Queue.Sharding,
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
