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

  def init(args) do
    Logger.info "Runner starting ... "
    {:ok, []}
  end

  def handle_cast( {:run, graph, :stop}, state ) do
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

      # tell scheduler that we are done
      Tskr.Scheduler.runner_done(self)
      {:noreply, state}
    end
  end

  def handle_cast( {:run, graph, taskname}, state ) do
    Logger.info "Started Task: #{inspect taskname}"

    {^taskname, taskstate} = :digraph.vertex state.graph, taskname
    graph_updates = (taskstate.code).run state.graph, taskname

    Logger.info "Finished Task: #{inspect taskname} | results: #{inspect graph_updates}"

    Tskr.Store.update(graph_updates)
    Tskr.Viz.write state.graph

    # tell scheduler that we are done
    Tskr.Scheduler.runner_done(self)
    {:noreply, state}
  end


end

