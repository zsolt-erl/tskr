defmodule Tsk.Executor do
  def run(graph, myself, inputs \\ [], outputs \\ []) do
    outputs |> Edge.updates( value: {:done, myself.hostname} )
  end
end

