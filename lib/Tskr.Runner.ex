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


  def handle_cast( {:run, graph, taskname}, state ) do
    {^taskname, taskStruct} = :digraph.vertex graph, taskname

    Logger.warn "Started Task: #{inspect taskname} #{inspect taskStruct.code}"
    
    inputs = get_inputs( graph, taskname )
    Logger.debug "Inputs: #{inspect inputs}"

    outputs = get_outputs( graph, taskname )
    Logger.debug "Outputs: #{inspect outputs}"

    graph_updates = List.flatten( (taskStruct.code).run graph, taskStruct, inputs, outputs )

    Logger.warn "Finished Task: #{inspect taskname} | results:\n"

    Tskr.Store.update graph_updates

    # tell scheduler that we are done
    Tskr.Scheduler.runner_done taskname
    {:noreply, state}
  end


  defp get_inputs(graph, taskname) do
    :digraph.in_edges( graph, taskname )
      |> Enum.map( &(:digraph.edge graph, &1) )
      |> Enum.map( fn({edgename, source, target, edgeStruct}) -> edgeStruct end )
  end


  defp get_outputs(graph, taskname) do
    :digraph.out_edges( graph, taskname )
      |> Enum.map( &(:digraph.edge graph, &1) )
      |> Enum.map( fn({edgename, source, target, edgeStruct}) -> edgeStruct end )
  end
end

