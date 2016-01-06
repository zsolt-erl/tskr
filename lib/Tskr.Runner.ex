defmodule Tskr.Runner do
  @moduledoc """
  Execute task and send result to update store
  """
  use GenServer
  require Logger

  def start_link(args, opts \\ []) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def run(pid, graph, taskname) do
    GenServer.cast(pid, {:run, graph, taskname})
  end

  ##############################
  # server callbacks
  ##############################

  def init(_args) do
    Logger.info "Runner starting ... "
    {:ok, []}
  end

  def handle_cast( {:run, graph, :stop}, state ) do
    {:stop, taskstate} = :digraph.vertex graph, :stop

    if not (Map.has_key?(taskstate, :executed) and taskstate.executed) do
      # this was not executed yet
      # need to execute it
      Logger.info "Started Task: :stop"

      new_tasktate = Map.put taskstate, :executed, true
      update_executed = %{op: :update_task, name: :stop, new_state: new_tasktate}
      graph_updates = (taskstate.code).run graph, :stop

      Logger.info "Finished Task: :stop | results: #{inspect graph_updates}"

      Tskr.Store.update( [update_executed] ++ graph_updates )

      # tell scheduler that we are done
      Tskr.Scheduler.runner_done :stop
    end
    {:noreply, state}
  end

  def handle_cast( {:run, graph, taskname}, state ) do
    {^taskname, taskStruct} = :digraph.vertex graph, taskname

    Logger.info "Started Task: #{inspect taskname} #{inspect taskStruct.code}"
    
    # inputs = []
    inputs = :digraph.in_edges( graph, taskname )
              |> Enum.map( &(:digraph.edge graph, &1) )
              |> Enum.map( fn({edgename, source, target, edgeStruct}) -> edgeStruct end )

    Logger.debug "Inputs: #{inspect inputs}"

    outputs = :digraph.out_edges( graph, taskname )
              |> Enum.map( &(:digraph.edge graph, &1) )
              |> Enum.map( fn({edgename, source, target, edgeStruct}) -> edgeStruct end )

    Logger.debug "Outputs: #{inspect outputs}"

    graph_updates = List.flatten( (taskStruct.code).run graph, taskStruct, inputs, outputs )

    Logger.info "Finished Task: #{inspect taskname} | results:\n"
    Enum.each graph_updates, &IO.inspect/1

    Tskr.Store.update graph_updates

    # tell scheduler that we are done
    Tskr.Scheduler.runner_done taskname
    {:noreply, state}
  end


end

