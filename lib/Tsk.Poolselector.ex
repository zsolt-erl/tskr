defmodule Tsk.Poolselector do
  alias Tskr.MongoPool
  import Tskr.Util
  require Logger

  @doc """
  initialize the tsk, get list of pools from the db
  """
  def run(graph, tskname, [%{value: :go}] = inputs, outputs) do
    Logger.warn "Poolselector first time run!"

    # get pool names from db
    query =%{"startTskName" => %{"$regex" => "G_qa.qa1s1..*"}, "relation" => "member", "endTskName" => %{"$regex" => "G_qa.qa1s1..*"}}
    cursor = Mongo.find MongoPool, "edges", query, limit: 3
    poolnames = cursor |> Enum.map( fn(edge) -> edge["endTskName"] end )
    {^tskname, tskstate} = :digraph.vertex graph, tskname
    new_state = Map.put tskstate, :poolnames, tl(poolnames)

    hostsel = Tsk.new code: Tsk.Hostselector
    [ 
      # park incoming edge
      #changeTarget( inputs, :park ),

      # update tsk state with poolnames
      # updateTsk(tskname, new_state),
      
      # add new host selector tsk
      #addTsk(hostsel),
      
      # connect host selector to pool selector
      #addEdge( hostsel, tskname),
      
      # update host selector with the pool name it needs to work on 
      # TODO this shouldn't need the code field again
      #updateTsk(hostsel, %{code: Tsk.Hostselector, poolname: hd(poolnames)})
    ]
  end

  def run(graph, tskname, inputs, outputs) do
    done_inputs = Enum.filter inputs, fn
      (%{value: {:done, _}}) -> true
      (_) -> false
    end
    done_poolnames = Enum.map done_inputs, fn(i)->elem(i.value, 1) end
    # update tsk state
    {^tskname, tskstate} = :digraph.vertex graph, tskname
    remaining_pools = tskstate.poolnames -- done_poolnames
    case remaining_pools do
      [] ->
        # we are done, update output
        #tskout(outputs, :done)
        []
      [next_pool | tail] ->
        []
        # create host selector for next pool
        # hostsel = [generateTskName, Tsk.Hostselector]
        # # update state with tail
        # new_state = %{tskstate | poolnames: tail}
        # graphUpdates [
        #   for i <- done_inputs do 
        #   delTsk(i.source)
        #   end,

        #   updateTsk(tskname, new_state),

        #   addTsk(hostsel),
        #   addEdge(hostsel, tskname),
        #   # TODO this shouldn't need the code field again
        #   updateTsk(hostsel, %{code: Tsk.Hostselector, poolname: next_pool}),
        # ]
    end
  end
end

