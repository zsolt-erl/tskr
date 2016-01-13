defmodule Tsk.Executor do
  def run(graph, myself, inputs \\ [], outputs \\ []) do
    IO.puts "......#{__MODULE__} finished:: hostname: #{myself.hostname}"
    outputs |> Edge.updates( value: {:done, myself.hostname} )
  end
end

