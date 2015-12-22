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

  def runner_done(taskname) do
    GenServer.call(__MODULE__, {:runner_done, taskname})
  end

  def start do
    send __MODULE__, :start
  end


  ##############################
  # server callbacks
  ##############################

  def init(args) do
    state = %{tasks_to_do: [], tasks_doing: [], graph: Tskr.Store.get_graph}
    Logger.info "scheduler starting ... #{inspect args}"
    # {:ok, state, 5000}
    {:ok, state}
  end


  def handle_call({:runner_done, taskname}, {worker_pid, _tag}, state = %{tasks_doing: tasks_doing}) do
    :poolboy.checkin(:runner_pool, worker_pid)

    new_state = %{state | tasks_doing: tasks_doing -- [taskname]}
    {:reply, :ok, new_state, 50}
  end


  def handle_call(any, _from, state) do
    Logger.warn "scheduler got call: #{inspect any}"
    {:reply, :ok, state, 5000}
  end


  def handle_info(:start, state = %{tasks_to_do: tasklist}) do
    Logger.info "#{__MODULE__} State: #{inspect state}"
    Logger.info "#{__MODULE__} Tasklist: #{inspect tasklist}"

    new_state =  state |> add_tasks |> give_out_work
    {:noreply, new_state, 5000}
  end


  def handle_info(:timeout, state) do
    new_state = 
      if length(state.tasks_to_do) > 0 do
        state |> give_out_work
      else
        state |> add_tasks |> give_out_work
      end
    {:noreply, new_state, 5000}
  end


  #################################################
  # private functions
  #################################################

  @doc """
  add new tasks to the todo list
  """
  defp add_tasks(state = %{tasks_to_do: tasklist, tasks_doing: tasks_doing}) do
    {pb_state, pb_workers, pb_overflow, pb_monitors} = :poolboy.status :runner_pool

    # get executable tasks
    case Tskr.Store.get_n_tasks(pb_workers * 2) do
      nil -> 
        Logger.info "No executable tasks"
        state
      {:ok, tasknames} ->
        Logger.info "Got executable tasks: #{inspect tasknames}"
        Logger.info "Not currently executing: #{inspect (tasknames--tasks_doing)}"

        updated_tasks_to_do = tasklist ++ (tasknames -- tasks_doing)
        %{state | tasks_to_do: updated_tasks_to_do}
    end
  end


  @doc """
  gives out work to idle workers
  """
  defp give_out_work(state = %{tasks_to_do: tasklist, graph: graph, tasks_doing: tasks_doing}) do
    {pb_state, pb_workers, pb_overflow, pb_monitors} = :poolboy.status :runner_pool

    {updated_to_do, updated_doing} = Enum.reduce(
      1..pb_workers,
      {tasklist, tasks_doing},
      fn
        (i, {[], doing}) -> {[], doing}
        (i, {[tasksH|tasksT], doing}) ->
          worker_pid = :poolboy.checkout :runner_pool
          Tskr.Runner.run(worker_pid, graph, tasksH)
          {tasksT, [tasksH|doing]}
      end)
    %{state | tasks_to_do: updated_to_do, tasks_doing: updated_doing}
  end

end

