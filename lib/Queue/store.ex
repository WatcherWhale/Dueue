defmodule Dueue.Queue.Store do
  use GenServer
  require Logger

  @name __MODULE__

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: @name)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:push, key, value}, _from, state) do
    case Map.fetch(state, key) do
      {:ok, queue} ->
        new_queue = queue ++ [value]
        new_state = Map.put(state, key, new_queue)
        {:reply, :ok, new_state}

      :error ->
        new_state = Map.put(state, key, [value])
        {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call({:pop, key}, _from, state) do
    case Map.fetch(state, key) do
      {:ok, queue} ->
        {value, new_queue} = List.pop_at(queue, 0)
        new_state = Map.put(state, key, new_queue)
        {:reply, value, new_state}

      :error ->
        {:reply, nil, state}
    end
  end

  @impl true
  def handle_call({:sync, key, queue}, _from, state) do
    Logger.info("Updated queue #{key}, from primary.")
    {:reply, :ok, Map.put(state, key, queue)}
  end
end
