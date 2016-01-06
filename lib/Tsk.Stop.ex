defmodule Tsk.Stop do
  @doc """
  This tsk does nothing by default.
  The scheduler will stop graph execution after executing this tsk.
  """
  
  import Tskr.Util

  def run(graph, myself) do
    Tskr.Viz.write graph
    [
      Edge.add Edge.new( source: myself, target: myself, value: 42 )
    ]
  end
end

