defmodule Tsk.Hostselector do
  import Tskr.Util

  def run(graph, myself, inputs, outputs) do
    :timer.sleep 5000
    outputs |> Edge.updates( value: {:done, myself.poolname} )
  end
end


