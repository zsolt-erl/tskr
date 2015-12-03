defmodule Task.Fib do
  def run(graph, taskname) do
    # get state of task
    {taskname, taskstate} = :digraph.vertex graph, taskname

    # get incoming edge and state
    [in_edge] = :digraph.in_edges graph, taskname
    {^in_edge, in_edge_source, ^taskname, inedge_state} = :digraph.edge graph, in_edge

    # get outgoing edge
    [out_edge] = :digraph.out_edges graph, taskname
    {^out_edge, ^taskname, out_edge_target, outedge_state} = :digraph.edge graph, out_edge

    cond do 
      inedge_state.value === 0 or inedge_state.value === 1 ->
        # update output with result
        new_edgestate = %{outedge_state | :value => inedge_state.value, :valid => true}
        [%{op: :update_edge, name: out_edge, new_state: new_edgestate}]
      true ->
        # replace current task with new tasks
        t1fib = {taskname, 1}
        t2fib = {taskname, 2}
        t3sum = {taskname, 3}
        [ 
          # delete old task and edges
          %{op: :delete_task, name: taskname},
          %{op: :delete_edge, name: in_edge},
          %{op: :delete_edge, name: out_edge},
          
          # add new tasks
          %{op: :add_task, name: t1fib, state: %{code: Task.Fib}}, 
          %{op: :add_task, name: t2fib, state: %{code: Task.Fib}}, 
          %{op: :add_task, name: t3sum, state: %{code: Task.Sum}}, 

          # add new edges
          %{op: :add_edge, name: nil, source: :start, target: t1fib, state: %{value: inedge_state.value-1, valid: true}},
          %{op: :add_edge, name: nil, source: :start, target: t2fib, state: %{value: inedge_state.value-2, valid: true}},
          %{op: :add_edge, name: nil, source: t1fib, target: t3sum, state: %{value: nil, valid: false}},
          %{op: :add_edge, name: nil, source: t2fib, target: t3sum, state: %{value: nil, valid: false}},
          %{op: :add_edge, name: out_edge, source: t3sum, target: out_edge_target, state: %{value: nil, valid: false}}
        ]
    end
  end
end


