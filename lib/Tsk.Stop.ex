defmodule Tsk.Stop do
  @doc """
  This tsk does nothing by default.
  The scheduler will stop graph execution after executing this tsk.
  """
  
  import Tskr.Util
  require Logger

  def run(graph, myself, inputs, outputs) do
    Tskr.Viz.write graph
    Logger.info "#################"
    Logger.info "# result: #{inspect hd(inputs).value}"
    Logger.info "#################"

    [
      Edge.add Edge.new( source: myself.name, target: myself.name, value: 42 )
    ]
  end
end

