defmodule Task.Setter do
  def run(graph, taskname) do
    # get state of task
    {taskname, taskstate} = :digraph.vertex graph, taskname

    # get all outgoing edges
    out_edges = :digraph.out_edges graph, taskname

    # create updates for all edges
    for edgename <- out_edges do
      # get current edge state
      {edgename, source, target, edgestate} = :digraph.edge graph, edgename

      # update edge state
      new_edgestate = %{edgestate | :value => taskstate.value, :valid => true }

      # create map for update operation
      %{op: :update_edge, name: edgename, new_state: new_edgestate}
    end
  end
end

