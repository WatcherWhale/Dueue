defmodule Dueue do
  use Application

  def start(_type, _args) do

    topologies = [
      gossip: [
        strategy: Cluster.Strategy.Gossip,
      ]
    ]
    children = [
      Dueue.Node,
      Dueue.Queue,
      Dueue.Http,
      {Cluster.Supervisor, [topologies, [name: Dueue.ClusterSupervisor]]},
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Dueue.Supervisor)
  end
end
