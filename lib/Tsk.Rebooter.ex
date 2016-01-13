defmodule Tsk.Rebooter do
  alias Tskr.MongoPool
  import Tskr.Util

  def run(graph, myself, inputs, outputs) do
    # get names of all the pools from mongodb
    #cursor = Mongo.find MongoPool, "edges", %{"startNodeName" => %{"$regex" => "G_qa.qa1s1..*"}}, limit: 20
    #IO.puts "Number of pools: #{inspect length(Enum.to_list(cursor))}"

    psel = Tsk.new code: Tsk.Poolselector
    
    IO.puts "#{__MODULE__} finished"

    [
      Tsk.del(myself),
      Tsk.add(psel),

      inputs  |> Edge.updates( target: psel.name ),
      outputs |> Edge.updates( source: psel.name )
    ]
  end
end


