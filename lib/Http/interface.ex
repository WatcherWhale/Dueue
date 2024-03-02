defmodule Dueue.Http.Interface do
  use Plug.Router

  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  @queue Dueue.Queue

  get "/pop" do
    value = GenServer.call(@queue, {:pop, "key"})
    if value !== nil do
      send_resp(conn, 200, value)
    else
      send_resp(conn, 404, "Queue is empty or does not exist")
    end
  end

  get "/push" do
    GenServer.call(@queue, {:push, "key", "test"})
    send_resp(conn, 200, "pushed")
  end
end
