defmodule Dueue.Http do
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      #Plug.Cowboy.child_spec(
      #  scheme: :http,
      #  plug: Dueue.Http.Interface,
      #  options: [
      #    port: 8001
      #  ]
      #)
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
