defmodule Task.Stop do
  @doc """
  This task does nothing by default.
  The scheduler will stop graph execution after executing this task.
  """
  
  import Tskr.Util

  def run(graph, taskname) do
    Tskr.Viz.write graph
    [addEdge(taskname, taskname, value: 42)]
  end
end

