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

  def runner_done do
    GenServer.call(__MODULE__, :runner_done)
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


  def handle_call(:runner_done, {worker_pid, _tag}, state) do
    :poolboy.checkin(:runner_pool, worker_pid)
    {:reply, :ok, state, 5000}
  end

  def handle_call(any, _from, state) do
    :io.format "scheduler got call: ~p~n", [any]
    {:reply, :ok, state, 5000}
  end


  def handle_info(:timeout, state) do
    {pb_state, pb_workers, pb_overflow, pb_monitors} = :poolboy.status :runner_pool

    # get executable tasks for idle workers
    case Tskr.Store.get_n_tasks(pb_workers) do
      nil -> 
        Logger.info "Can't execute any tasks"
        :ok
      {:ok, tasknames} ->
        Logger.info "Got executable tasks: #{inspect tasknames}"
        for taskname <- tasknames do
          worker_pid = :poolboy.checkout :runner_pool
          Tskr.Runner.run(worker_pid, state.graph, taskname)
        end
    end

    {:noreply, state, 5000}
  end

end

