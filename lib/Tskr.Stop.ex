defmodule Task.Stop do
  @doc """
  This task does nothing by default.
  The scheduler will stop graph execution after executing this task.
  """
  
  def run(graph, taskname) do
    []
  end
end

