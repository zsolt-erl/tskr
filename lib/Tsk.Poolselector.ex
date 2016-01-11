defmodule Tsk.Poolselector do
  alias Tskr.MongoPool
  import Tskr.Util
  require Logger

  @doc """
  initialize the task, get list of pools from the db
  """
  def run(_graph, myself, [%{value: :go}] = inputs, _outputs) do
    Logger.warn "Poolselector first time run!"

    # get pool names from db
    # query =%{"startNodeName" => %{"$regex" => "G_qa.qa1s1..*"}, "relation" => "member", "endNodeName" => %{"$regex" => "G_qa.qa1s1..*"}}
    query =%{"startNodeName" => %{"$regex" => "G_qa.qa1s1..*"}, "relation" => "member", "endNodeName" => %{"$regex" => "^((?!^G_).)*$" }}
    cursor = Mongo.distinct MongoPool, "edges", "startNodeName", query, limit: 3
    # poolnames = cursor |> Enum.map( fn(edge) -> edge["endNodeName"] end )
    poolnames = Enum.slice cursor, 0..2

    Logger.warn "Poolnames: #{inspect poolnames}"

    hostsel = Tsk.new code: Tsk.Hostselector

    [ 
      # park incoming edge
      inputs |> Edge.updates( target: :park ),

      # update task state with poolnames
      myself |> Tsk.update( poolnames: tl(poolnames) ),
      
      # add new host selector task
      hostsel |> Tsk.add,

      # update host selector with the pool name it needs to work on
      hostsel |> Tsk.update( poolname: hd(poolnames) ),
      
      {:go, hd(poolnames)} ~>> hostsel,
      # connect host selector to pool selector
      hostsel ~> myself
    ]
  end


  def run(_graph, myself, inputs, outputs) do
    done_inputs = Enum.filter inputs, fn
      (%{value: {:done, _}}) -> true
      (_) -> false
    end
    done_poolnames = Enum.map done_inputs, fn(i)->elem(i.value, 1) end

    remaining_pools = myself.poolnames -- done_poolnames

    case remaining_pools do
      [] ->
        # we are done, update output
        outputs |> Edge.updates(value: :done)

      [next_pool | tail] ->
        hostsel = Tsk.new code: Tsk.Hostselector 
        [
          myself |> Tsk.update(poolnames: tail),

          # delete sources of done inputs
          # TODO ugly hack to make Tsk.del work, Tsk.del needs a task but the edge.source is a task name
          done_inputs |> Enum.map( &(Tsk.del( %{name: &1.source} ) ) ),

          hostsel |> Tsk.add,
          hostsel |> Tsk.update( poolname: next_pool ),
          {:go, next_pool} ~>> hostsel,
          hostsel ~> myself
        ]
    end
  end
end

