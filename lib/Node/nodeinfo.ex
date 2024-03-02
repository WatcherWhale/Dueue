defmodule Dueue.NodeInfo do
  defstruct [
    timer_ref: :none,
    formed: false,
    joined: false,
    leader: :none,
  ]
end
