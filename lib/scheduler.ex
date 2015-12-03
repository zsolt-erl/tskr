defmodule Tskr.Scheduler do
  @moduledoc """
  Schedules tasks for execution.
  - find a task on the graph that has all inputs ready
  - send task to executer
  """
  use GenServer
  require Logger

  def start_link(args, opts \\ []) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  ##############################
  # server callbacks
  ##############################

  def init(args) do
    state = %{executers: [], graph: Tskr.Store.get_graph}
    Logger.info "scheduler starting ... #{inspect args}"
    {:ok, state, 5000}
    #{:ok, state}
  end


  def handle_call(any, _from, state) do
    :io.format "scheduler got call: ~p~n", [any]
    {:reply, :ok, state, 5000}
  end


  #def handle_info(any, state) do
    #  {:noreply, state, 5000}
    #end

  def handle_info(:timeout, state) do
    #Logger.info "got :timeout"

    # get an executable task from store
    case Tskr.Store.get_task do

      nil -> 
      #Logger.info "Can't execute any tasks"
        :ok
      
      {:ok, :stop} ->
        {:stop, taskstate} = :digraph.vertex state.graph, :stop

        if not (Map.has_key?(taskstate, :executed) and taskstate.executed) do
          # this was not executed yet
          # need to execute it
          Logger.info "Started Task: :stop"
          new_tasktate = %{taskstate| :executed => true}
          update_executed = %{op: :update_task, name: :stop, new_state: new_tasktate}
          graph_updates = (taskstate.code).run state.graph, :stop
          Logger.info "Finished Task: :stop | results: #{inspect graph_updates}"

          Tskr.Store.update( [update_executed] ++ graph_updates )
          Tskr.Viz.write state.graph
        end

      {:ok, taskname} ->
        Logger.info "Started Task: #{inspect taskname}"
    
        {^taskname, taskstate} = :digraph.vertex state.graph, taskname

        graph_updates = (taskstate.code).run state.graph, taskname
        Logger.info "Finished Task: #{inspect taskname} | results: #{inspect graph_updates}"
        Tskr.Store.update(graph_updates)
        Tskr.Viz.write state.graph
        # pick an idle executer (who starts the executers?)
        # send work to executer
        :ok

    end

    {:noreply, state, 5000}
  end
end

