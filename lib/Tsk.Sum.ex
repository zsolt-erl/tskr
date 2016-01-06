defmodule Tsk.Sum do
  def run(graph, myself, inputs \\ [], outputs \\ []) do
    # calculate sum of edge values
    sum = inputs 
          |> Enum.map( &(&1.value) )
          |> Enum.sum
    
    outputs |> Edge.updates( value: sum )
  end
end

