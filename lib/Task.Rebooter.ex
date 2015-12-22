defmodule Task.Rebooter do
  alias Tskr.MongoPool
  import Tskr.Util

  def run(graph, taskname, inputs, outputs) do
    # get names of all the pools from mongodb
    cursor = Mongo.find MongoPool, "edges", %{"startNodeName" => %{"$regex" => "G_qa.qa1s1..*"}}, limit: 20
    IO.puts "Number of pools: #{inspect length(Enum.to_list(cursor))}"

    pselector = [generateTaskName(), Task.Poolselector]

    graphUpdates [
      delTask(taskname),
      addTask( pselector ), 
      changeTarget(inputs, pselector),
      changeSource(outputs, pselector)
      ]
  end
end


