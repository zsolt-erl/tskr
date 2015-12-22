defmodule Tskr.Util do
  import UUID

  def graphUpdates(gu), do: List.flatten(gu)
  
  ############################################################################
  # task functions
  ############################################################################
  def generateTaskName, do: String.to_atom UUID.uuid4()

  def addTask([name, code]) do  
    %{op: :add_task, name: name, state: %{code: code}}
  end
  
  def updateTask([name, _code], new_state) do
    %{op: :update_task, name: name, new_state: new_state}
  end
  def updateTask(name, new_state) do
    %{op: :update_task, name: name, new_state: new_state}
  end
  
  def taskout(outputs, value) do
    for o <- outputs do
      %{op: :update_edge_value, name: o.name, new_value: value}
    end
  end

  ############################################################################
  # edge functions
  ############################################################################
  @doc """
  args can be:
  name, value, filter
  filter is an expression given as a string that can be evalutated (eg. "{:failed, _}" or "true")
  """
  def addEdge(source, target, args \\ []) do
    sourceName = cond do
      is_atom(source) -> source
      [taskname, taskcode] = source -> taskname
    end
    targetName = cond do
      is_atom(target) -> target
      [taskname, taskcode] = target -> taskname
    end

    name = if Keyword.has_key?(args, :name), do: args[:name], else: nil
    {value, valid} = if Keyword.has_key?(args, :value), do: {args[:value], true}, else: {nil, false}

    filter_clause = if Keyword.has_key?(args, :filter), do: args[:filter], else: "_"
    filter = fn(x) ->
      try do
        Code.eval_string filter_clause <> "=x", x: x 
        true
      rescue 
        MatchError -> false
      end
    end

    state = %{value: value, valid: valid, filter: filter}
    %{op: :add_edge, name: name, source: sourceName, target: targetName, state: state}
  end

  def changeTarget(edges, [taskname, _taskcode]) do
    changeTargetFun(edges, taskname)
  end
  def changeTarget(edges, taskname) when is_atom(taskname) do
    changeTargetFun(edges, taskname)
  end
  def changeTargetFun(edges, new_target) do
    for e <- edges do
      %{op: :add_edge, 
        name: e.name, 
        source: e.source, 
        target: new_target, 
        state: e.state
      }
    end
  end


  def changeSource(edges, [taskname, _taskcode]) do
    changeSourceFun(edges, taskname)
  end
  def changeSource(edges, taskname) when is_atom(taskname) do
    changeSourceFun(edges, taskname)
  end
  def changeSourceFun(edges, new_source) do
    for e <- edges do
      %{op: :add_edge, 
        name: e.name, 
        source: new_source, 
        target: e.target, 
        state: e.state
      }
    end
  end


  def addTask(name, code), do:  %{op: :add_task, name: name, state: %{code: code}}
  def delTask(name), do: %{op: :delete_task, name: name}


  def delEdge(name), do: %{op: :delete_edge, name: name}
  def updateEdge(name, new_state), do: %{op: :update_edge, name: name, new_state: new_state}
  def updateEdgeValue(name, new_value), do: %{op: :update_edge_value, name: name, new_value: new_value}





  def getInEdges(graph, taskname) do
    for edgename <- :digraph.in_edges graph, taskname do
      :digraph.edge graph, edgename
    end
  end


  def getOutEdges(graph, taskname) do 
    for edgename <- :digraph.out_edges graph, taskname do
      :digraph.edge graph, edgename
    end
  end


  def updateSource(edges, new_source) do
    for edge <- edges do
      {edgename, source, target, state} = edge
      %{op: :add_edge, name: edgename, source: new_source, target: target, state: state}
    end
  end

  def updateTarget(edges, new_target) do
    for edge <- edges do
      {edgename, source, target, state} = edge
      %{op: :add_edge, name: edgename, source: source, target: new_target, state: state}
    end
  end

  def replaceTask graph, taskname, edgeMap do
    Enum.reduce edgeMap, [delTask(taskname)], 
    fn
      ( {sourceTaskCode, targetTaskCode}, acc ) when is_atom(sourceTaskCode) and is_atom(targetTaskCode) ->
        # create edge and create tasks with random names
        sourceTaskName = UUID.uuid4()
        targetTaskName = UUID.uuid4()

        acc ++ [
          addTask(sourceTaskName, sourceTaskCode),
          addTask(targetTaskName, targetTaskCode),
          addEdge(sourceTaskName, targetTaskName)
        ]

      ( {[sourceTaskName, sourceTaskCode], [targetTaskName, targetTaskCode]}, acc ) ->
        # create edge and create tasks with given name and code
        acc ++ [
          addTask(sourceTaskName, sourceTaskCode),
          addTask(targetTaskName, targetTaskCode),
          addEdge(sourceTaskName, targetTaskName)
        ]

      ( {{edgeValue}, taskCode}, acc ) when is_atom(taskCode)->
        # create edge with value set and task with random name
        taskName = UUID.uuid4()
        acc ++ [
          addTask(taskName, taskCode),
          addEdge(:start, taskName, value: edgeValue)
        ]

      ( {{edgeValue}, [taskName, taskCode]}, acc ) ->
        # create edge with value set and task with given name and code
        acc ++ [
          addTask(taskName, taskCode),
          addEdge(:start, taskName, value: edgeValue)
        ]
    end
  end

    #myInputs = getInNames graph, taskname
    #myOutputs = getOutNames graph, taskname

    #inputUpdates = for input <- myInputs do
      #  {^input, ^taskname, inedge_target, inedge_state} = :digraph.edge graph, input
      #end


end
