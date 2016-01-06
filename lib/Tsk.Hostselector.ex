defmodule Tsk.Hostselector do
  import Tskr.Util

  def run(graph, myself, inputs, outputs) do
    :timer.sleep 10000
    outputs |> Edge.updates( value: myself.poolname )
  end
end


