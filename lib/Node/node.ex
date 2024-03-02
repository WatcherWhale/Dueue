defmodule Dueue.Node do
  use GenServer
  require Logger

  @name __MODULE__

  def start_link(_) do
    GenServer.start_link(__MODULE__, %Dueue.NodeInfo{}, name: @name)
  end

  @impl true
  def init(state) do
    :net_kernel.monitor_nodes(true)
    {:ok, start_timer(state)}
  end

  defp start_timer(state) do
    timer_ref = Process.send_after(self(), {:cluster_form}, 5000)
    %{state | timer_ref: timer_ref}
  end

  @impl true
  def handle_info({:cluster_form}, state) do
    new_state = start_timer(state)

    if !state.formed do
      {:noreply, form_cluster(new_state)}
    else
      {:noreply, new_state}
    end
  end

  @impl true
  def handle_info({:nodedown, node}, state) do
    # A node left the cluster
    Logger.info("--- Node down: #{node}")

    state = Map.put(state, node, false)

    {:noreply, state}
  end

  @impl true
  def handle_info({:nodeup, node}, state) do
    # A new node joined the cluster
    Logger.info("--- Node up: #{node}")

    if state.leader === Node.self() do
      GenServer.call({@name, node}, {:cluster, Node.self()})
    end

    {:noreply, state}
  end

  def form_cluster(state) do
    Logger.info("Forming a cluster")

    nodes = (Node.list() |> length()) + 1
    quorate_min = floor((nodes + 1) / 2)

    # Ask other Nodes to promote self to leader
    votes =
      Enum.reduce(Node.list(), 1, fn node, votes ->
        status = GenServer.call({@name, node}, {:form})

        if status == :accept do
          votes + 1
        else
          votes
        end
      end)

    if nodes > 1 && votes >= quorate_min do
      Logger.info("Formed a cluster")

      # Inform other nodes of cluster state
      Node.list()
      |> Enum.each(fn node -> GenServer.call({@name, node}, {:cluster, Node.self()}) end)

      # Stop form_cluster
      Process.cancel_timer(state.timer_ref)

      # Return new state
      %{state | formed: true, joined: true, leader: Node.self()}
    else
      Logger.info("Failed forming a cluster")
      state
    end
  end

  @impl true
  def handle_call({:info}, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:leader_info}, _from, state) do
    leader_info = GenServer.call({@name, state.leader}, {:info})
    {:reply, leader_info, state}
  end

  @impl true
  def handle_call({:form}, from, state) do
    if state.formed do
      if state.leader === Node.self() do
        GenServer.call({@name, from}, {:cluster, Node.self()})
      end
      {:reply, :reject, state}
    else
      {:reply, :accept, state}
    end
  end

  @impl true
  def handle_call({:cluster, node}, _from, state) do
    Logger.info("Joined cluster with leader #{node}")
    {:reply, :ok, %{state | formed: true, joined: true, leader: node}}
  end
end
