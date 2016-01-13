defmodule Tsk.Hostselector do
  alias Tskr.MongoPool
  import Tskr.Util
  require Logger

  @doc """
  initialize the task, get list of hosts from the db
  """
  def run(_graph, myself, [%{value: {:go, poolname}}] = inputs, _outputs) do
    IO.puts "....#{__MODULE__} started"
    IO.puts "....#{__MODULE__} init:: poolname: #{poolname}"

    # get host names from db
    hostnames = Mongo.find(
      MongoPool, "edges",
      %{"startNodeName": poolname, "relation": "member"},
      projection: %{"endNodeName": 1}
    ) |> Enum.to_list |> Enum.map( &(&1["endNodeName"]) )

    max_executors = case div(length(hostnames), 10) do
      0 -> 1
      x -> trunc(x)
    end

    IO.puts "....#{__MODULE__} init:: hostnames: #{inspect hostnames}, max_executors: #{inspect max_executors}"
    {hosts_doing, hosts_todo} = Enum.split hostnames, max_executors

    # create executors
    executors = for host <- hosts_doing do
      Tsk.new code: Tsk.Executor, hostname: host
    end

    [ 
      # park incoming edge
      inputs |> Edge.updates( target: :park ),

      # update task state with hostnames
      myself |> Tsk.update( doing: hosts_doing, todo: hosts_todo, max_executors: max_executors, poolname: poolname ),

      (for e <- executors, do: [Tsk.add(e), e ~> myself])
    ]
  end


  def run(_graph, myself, inputs, outputs) do
    ###################################################
    # process input messages
    ###################################################
    {new_doing, new_todo, new_max_executors, updates} = Enum.reduce inputs, {myself.doing, myself.todo, myself.max_executors, []},
      fn
        ###################################################
        # input = {:done, hostname}
        ###################################################
        (%{value: {:done, host_done}} = input, {acc_doing, acc_todo, acc_max_executors, acc_updates}) -> 
          # step 1: process done host
          doing1 = acc_doing -- [host_done]
          todo1 = acc_todo
          update1 = acc_updates ++ [Tsk.del(%{name: input.source})] # delete executor that sent the message

          # step 2: create new executor if there's more todo
          {doing2, todo2, update2} = 
            if todo1 != [] do
              [head_todo | ntodo] = todo1
              ndoing = [head_todo | doing1]
              executor = Tsk.new code: Tsk.Executor, hostname: head_todo
              nupdate = update1 ++ [Tsk.add(executor), executor ~> myself]
              {ndoing, ntodo, nupdate}
            else
              {doing1, todo1, update1}
            end

          # step 3: check if we are fully done
          {doing3, todo3, update3} = 
            if doing2 == [] and todo2 == [] do
              IO.puts "....#{__MODULE__} finished"
              nupdate = update2 ++ (outputs |> Edge.updates(value: {:done, myself.poolname}))
              {doing2, todo2, nupdate}
            else
              {doing2, todo2, update2}
            end

          {doing3, todo3, acc_max_executors, update3}

        ###################################################
        # input = {:fail, hostname}
        ###################################################
        (%{value: {:fail, host_failed}} = input, {acc_doing, acc_todo, acc_max_executors, acc_updates}) -> 
          # step 1: process failed host
          doing1 = acc_doing -- [host_failed]
          todo1 = acc_todo
          maxe1 = acc_max_executors - 1
          update1 = acc_updates ++ [Tsk.del(%{name: input.source})] # delete executor that sent the message

          # step 2: create new executor if there's more todo and we didn't reach the max_executor limit
          {doing2, todo2, maxe2, update2} = 
            if todo1 != [] and length(doing1) < maxe1 do
              [head_todo | ntodo] = todo1
              ndoing = [head_todo | doing1]
              executor = Tsk.new code: Tsk.Executor, hostname: head_todo
              nupdate = update1 ++ [Tsk.add(executor), executor ~> myself]
              {ndoing, ntodo, maxe1, nupdate}
            else
              {doing1, todo1, maxe1, update1}
            end

          # step 3: check if we are fully done
          {doing3, todo3, maxe3, update3} = 
            if doing2 == [] and todo2 == [] do
              IO.puts "....#{__MODULE__} finished"
              nupdate = update2 ++ (outputs |> Edge.updates(value: {:done, myself.poolname}))
              {doing2, todo2, maxe2, nupdate}
            else
              {doing2, todo2, maxe2, update2}
            end

          {doing3, todo3, maxe3, update3}
      end

    updates ++ [ myself |> Tsk.update( doing: new_doing, todo: new_todo, max_executors: new_max_executors) ]
  end
end

