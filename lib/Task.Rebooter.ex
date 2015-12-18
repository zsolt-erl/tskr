defmodule Task.Rebooter do
  alias Tskr.MongoPool
  import Tskr.Util

  def run(graph, taskname, inputs, outputs) do
    # get names of all the pools from mongodb
    cursor = Mongo.find MongoPool, "edges", %{"startNodeName" => %{"$regex" => "G_qa.qa1s1..*"}}, limit: 20
    Enum.to_list(cursor) |> IO.inspect

    ein = getInEdges graph, taskname
    eout = getOutEdges graph, taskname
    t1f = [generateTaskName(), Task.Fib]

    replaceTask(graph, taskname, %{ {9} => t1f })
    ++ ( ein |> updateTarget(:park) )
    ++ ( eout |> updateSource(hd(t1f)) )

  end
end


