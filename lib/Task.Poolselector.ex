defmodule Task.Poolselector do
  alias Tskr.MongoPool
  import Tskr.Util
  require Logger

  @doc """
  initialize the task, get list of pools from the db
  """
  def run(graph, taskname, [%{value: :go}] = inputs, outputs) do
    Logger.warn "Poolselector first time run!"

    # get pool names from db
    query =%{"startNodeName" => %{"$regex" => "G_qa.qa1s1..*"}, "relation" => "member", "endNodeName" => %{"$regex" => "G_qa.qa1s1..*"}}
    cursor = Mongo.find MongoPool, "edges", query, limit: 3
    poolnames = cursor |> Enum.map( fn(edge) -> edge["endNodeName"] end )
    {^taskname, taskstate} = :digraph.vertex graph, taskname
    new_state = Map.put taskstate, :poolnames, tl(poolnames)

    hostsel = [generateTaskName, Task.Hostselector]
    [ 
      # park incoming edge
      changeTarget( inputs, :park ),

      # update task state with poolnames
      updateTask(taskname, new_state),
      
      # add new host selector task
      addTask(hostsel),
      
      # connect host selector to pool selector
      addEdge( hostsel, taskname),
      
      # update host selector with the pool name it needs to work on 
      # TODO this shouldn't need the code field again
      updateTask(hostsel, %{code: Task.Hostselector, poolname: hd(poolnames)})
    ]
  end

  def run(graph, taskname, inputs, outputs) do
    done_inputs = Enum.filter inputs, fn
      (%{value: {:done, _}}) -> true
      (_) -> false
    end
    done_poolnames = Enum.map done_inputs, fn(i)->elem(i.value, 1) end
    # update task state
    {^taskname, taskstate} = :digraph.vertex graph, taskname
    remaining_pools = taskstate.poolnames -- done_poolnames
    case remaining_pools do
      [] ->
        # we are done, update output
        taskout(outputs, :done)
      [next_pool | tail] ->
        # create host selector for next pool
        hostsel = [generateTaskName, Task.Hostselector]
        # update state with tail
        new_state = %{taskstate | poolnames: tail}
        graphUpdates [
          for i <- done_inputs do 
          delTask(i.source)
          end,

          updateTask(taskname, new_state),

          addTask(hostsel),
          addEdge(hostsel, taskname),
          # TODO this shouldn't need the code field again
          updateTask(hostsel, %{code: Task.Hostselector, poolname: next_pool}),
        ]
    end
  end
end

