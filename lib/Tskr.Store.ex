defmodule Tskr.Store do
  use GenServer
  require Logger

  #############################################################################
  # server client
  #############################################################################

  def start_link(args, opts) do
    GenServer.start_link(__MODULE__, args, opts)
  end


  def get_graph do
    GenServer.call __MODULE__, :get_graph
  end


  @doc """
  load nodes and edges from application config
  """
  def load_graph do
    GenServer.call __MODULE__, :load_graph
  end


  @doc """
  returns an executable task
  (an executable task has all inputs ready and no valid output yet)
  """
  def get_task do
    GenServer.call __MODULE__, :get_task
  end


  @doc """
  returns a list of max. N executable tasks
  (an executable task has all inputs ready and no valid output yet)
  """
  def get_n_tasks(n) do
    GenServer.call __MODULE__, {:get_n_tasks, n}
  end


  
  @doc """
  process updates to graph
  """
  def update(oplist) do
    GenServer.call __MODULE__, {:update, oplist}
  end

  #############################################################################
  # callbacks
  #############################################################################

  ###################################
  # INIT
  ###################################
  def init(args) do
    Logger.info "Store init Arguments #{inspect args}"
    # graph = :digraph.new([:acyclic, :protected])
    graph = :digraph.new([:cyclic, :protected])
    state = %{graph: graph}
    {:ok, state}
  end

  ###################################
  # GET GRAPH
  ###################################
  def handle_call(:get_graph, _from, state) do
    {:reply, state.graph, state}
  end

  ###################################
  # LOAD GRAPH
  ###################################
  def handle_call(:load_graph, _from, state) do
    nodes = Application.get_env :tskr, :nodes
    edges = Application.get_env :tskr, :edges
    for node <- nodes, do: :digraph.add_vertex state.graph, node.name, node.state
    for edge <- edges do
      :digraph.add_edge(state.graph, edge.name, edge.source, edge.target, edge.label) 
      :io.format( ".")
    end
    IO.puts ""

    {:reply, :ok, state}
  end

  ###################################
  # GET TASK
  ###################################
  def handle_call(:get_task, _from, state) do
    nodes = :digraph.vertices state.graph

    case find_executable(nodes, state) do
      nil -> {:reply, nil, state}
      task -> {:reply, {:ok, task}, state}
    end
  end


  ###################################
  # GET N TASKS
  ###################################
  def handle_call({:get_n_tasks, n}, _from, state) do
    Logger.info "#{__MODULE__} getting #{n} tasks"
    nodes = :digraph.vertices state.graph
    {:reply, find_n_executables(nodes, [], n, state), state}
  end


  ###################################
  # UPDATE
  ###################################
  def handle_call({:update, oplist}, _from, state) do
    update_results =
      for operation <- oplist do
        Logger.debug "Tskr.Store.update operation: #{inspect operation}"
        case operation do
          
          %{op: :delete_edge, name: edgename} ->
            :digraph.del_edge state.graph, edgename

          %{op: :delete_task, name: taskname} ->
            :digraph.del_vertex state.graph, taskname

          %{op: :add_task, name: taskname, state: taskstate} ->
            :digraph.add_vertex state.graph, taskname, taskstate

          %{op: :add_edge, name: nil, source: source, target: target, state: edgestate} ->
            :digraph.add_edge state.graph, source, target, edgestate

          %{op: :add_edge, name: edgename, source: source, target: target, state: edgestate} ->
            :digraph.add_edge state.graph, edgename, source, target, edgestate

          %{op: :update_edge, name: edgename, new_state: new_edgestate} ->
            {^edgename, source, target, edgestate} = :digraph.edge state.graph, edgename
            :digraph.add_edge state.graph, edgename, source, target, new_edgestate

          %{op: :update_edge_value, name: edgename, new_value: new_value} ->
            {^edgename, source, target, edgestate} = :digraph.edge state.graph, edgename
            new_state = %{edgestate | value: new_value, valid: true}
            :digraph.add_edge state.graph, edgename, source, target, new_state

          %{op: :update_task, name: taskname, new_state: new_taskstate} ->
            {^taskname, taskstate} = :digraph.vertex state.graph, taskname
            :digraph.add_vertex state.graph, taskname, new_taskstate

          _ -> 
            {:unknown_op, operation}
        end

      end
    Logger.debug "Update Results: #{inspect update_results}"

    {:reply, {:ok, update_results}, state}
  end


  #############################################################################
  # private functions
  #############################################################################
  # find an executable task
  defp find_executable([], state), do: nil
  defp find_executable([tasksH|tasksT], state) do
    # input for task is only valid if all input edges are valid (or there's no input)
    input_valid = Enum.reduce(:digraph.in_edges(state.graph, tasksH), true, fn(edgename, acc) ->
      {^edgename, _start, _end, edgelabel} = :digraph.edge state.graph, edgename
      Logger.debug ">>> in edge #{inspect edgename} state: #{inspect edgelabel}"
      acc and edgelabel.valid
    end)

    # check if output exists
    output_exists = Enum.reduce(:digraph.out_edges(state.graph, tasksH), false, fn(edgename, acc) ->
      # {edgename, _start, _end, edgelabel} = :digraph.edge state.graph, edgename
      {^edgename, _start, _end, edgelabel} = :digraph.edge state.graph, edgename
      Logger.debug ">>> out edge #{inspect edgename} state: #{inspect edgelabel}"
      acc or edgelabel.valid
    end)
    
    executable = input_valid and (not output_exists)
    Logger.debug ">>> task: #{inspect tasksH} executable: #{executable} input_valid: #{input_valid} output exists: #{output_exists}"
    if executable do
      tasksH
    else
      find_executable tasksT, state
    end
  end


  # find max N executable tasks
  defp find_n_executables([], [], _n, state), do: nil
  defp find_n_executables([], executables, _n, state), do: {:ok, executables}
  defp find_n_executables(tasks, executables, 0, state), do: {:ok, executables}

  defp find_n_executables([tasksH|tasksT], executables, n, state) do
    # input for task is only valid if all input edges are valid (or there's no input)
    input_valid = Enum.reduce(:digraph.in_edges(state.graph, tasksH), true, fn(edgename, acc) ->
      {^edgename, _start, _end, edgelabel} = :digraph.edge state.graph, edgename
      Logger.debug ">>> in edge #{inspect edgename} state: #{inspect edgelabel}"
      acc and edgelabel.valid
    end)

    # check if output exists
    output_exists = Enum.reduce(:digraph.out_edges(state.graph, tasksH), false, fn(edgename, acc) ->
      # {edgename, _start, _end, edgelabel} = :digraph.edge state.graph, edgename
      {^edgename, _start, _end, edgelabel} = :digraph.edge state.graph, edgename
      Logger.debug ">>> out edge #{inspect edgename} state: #{inspect edgelabel}"
      acc or edgelabel.valid
    end)
    
    executable = input_valid and (not output_exists)
    Logger.debug ">>> task: #{inspect tasksH} executable: #{executable} input_valid: #{input_valid} output exists: #{output_exists}"
    if executable do
      find_n_executables tasksT, [tasksH | executables], n-1, state
    else
      find_n_executables tasksT, executables, n, state
    end
  end
end

