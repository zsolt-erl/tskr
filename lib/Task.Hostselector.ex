defmodule Task.Hostselector do
  import Tskr.Util

  def run(graph, taskname, inputs, outputs) do
    {^taskname, taskstate} = :digraph.vertex graph, taskname
    :timer.sleep 10000
    for o <- outputs do
      updateEdgeValue o.name, {:done, taskstate.poolname}
    end
  end
end


