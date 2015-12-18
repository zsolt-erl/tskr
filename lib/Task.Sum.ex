defmodule Task.Sum do
  def run(graph, taskname, inputs \\ [], outputs \\ []) do
    # get state of task
    {taskname, taskstate} = :digraph.vertex graph, taskname

    # get incoming edges and states
    in_edges = :digraph.in_edges graph, taskname
    
    # calculate sum of edge values
    sum = 
      for in_edge <- in_edges do
        {^in_edge, _, _, edgestate} = :digraph.edge graph, in_edge
        edgestate.value
      end |> Enum.sum

    # create update operation
    [out_edge] = :digraph.out_edges graph, taskname
    {^out_edge, _, _, outedge_state} = :digraph.edge graph, out_edge
    new_edgestate = %{outedge_state | :value => sum, :valid => true}
    [%{op: :update_edge, name: out_edge, new_state: new_edgestate}]
  end
end

