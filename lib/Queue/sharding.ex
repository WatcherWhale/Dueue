defmodule Dueue.Queue.Sharding do
  use GenServer
  require Logger

  @name Dueue.Queue
  @store Dueue.Queue.Store

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: @name)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:info}, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:push, key, value}, _from, state) do
    if is_owner_local(state, key) do
      {:reply, push(key, value), state}
    else
      # Ask leader or let leader elect an owner
      owner = get_owner(state, key)
      new_state = Map.put(state, key, owner)

      if owner.primary === Node.self() do
        {:reply, push(key, value), new_state}
      else
        {:reply, GenServer.call({@name, owner.primary}, {:push, key, value}), new_state}
      end
    end
  end

  @impl true
  def handle_call({:pop, key}, _from, state) do
    if is_owner_local(state, key) do
      {:reply, pop(key), state}
    else
      # Ask leader or let leader elect an owner
      owner = get_owner(state, key)
      new_state = Map.put(state, key, owner)

      if owner.primary === Node.self() do
        {:reply, pop(key), new_state}
      else
        {:reply, GenServer.call({@name, owner.primary}, {:pop, key}), new_state}
      end
    end
  end

  @impl true
  def handle_call({:get_owner, key}, _from, state) do
    owner = get_owner(state, key)
    {:reply, get_owner(state, key), Map.put(state, key, owner)}
  end

  defp get_leader() do
    cluster_info = GenServer.call(Dueue.Node, {:info})
    cluster_info.leader
  end

  defp is_owner_local(state, key) do
    case Map.fetch(state, key) do
      {:ok, owner} ->
        owner.primary === Node.self()

      :error ->
        false
    end
  end

  defp get_owner_leader(state, key) do
    case Map.fetch(state, key) do
      {:ok, owner} ->
        owner

      :error ->
        get_shard(key)
    end
  end

  defp get_owner(state, key) do
    leader = get_leader()

    cond do
      # If you are a leader respond with the owner
      leader === Node.self() ->
        get_owner_leader(state, key)

      # Ask leader for owner
      true ->
        GenServer.call({@name, leader}, {:get_owner, key})
    end
  end

  defp push(key, value) do
    GenServer.call(@store, {:push, key, value})
  end

  defp pop(key) do
    GenServer.call(@store, {:pop, key})
  end

  defp get_shard(key) do
    nodes = Node.list() ++ [Node.self()]

    pShard =
      :crypto.hash(:md5, key)
      |> Base.encode16()
      |> String.to_integer(16)
      |> rem(length(nodes))
    sShard = pShard + 1
      |> rem(length(nodes))

    {primary, _} = List.pop_at(nodes, pShard)
    {secondary, _} = List.pop_at(nodes, sShard)

    %Dueue.Queue.ShardLocation{primary: primary, secondary: secondary}
  end
end
