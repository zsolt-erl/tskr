defmodule Tsk do
  import UUID

  defp defaultTsk, do: %{name: String.to_atom(UUID.uuid4), code: nil}

  def new(fieldUpdates), do: Enum.into(fieldUpdates, defaultTsk)

  # execute tsk operations on a graph
  def doAdd(graph, tsk), do: :digraph.add_vertex graph, tsk.name, tsk
  def doDel(graph, tsk), do: :digraph.del_vertex graph, tsk.name
  def doUpdate(graph, tsk, changes) do
    # changes is a keyword list
    new_tsk = 
      Enum.reduce changes, tsk, fn({ch_key, ch_value}, acc) -> 
        Map.put(acc, ch_key, ch_value)
      end
    Tsk.doAdd graph, new_tsk
  end

  # create messages that can be processed by Tskr.Store
  def add(tsk),             do: %{op: &Tsk.doAdd/2, args: [tsk]}
  def del(tsk),             do: %{op: &Tsk.doDel/2, args: [tsk]}
  def update(tsk, changes), do: %{op: &Tsk.doUpdate/3, args: [tsk, changes]}
end


defmodule Edge do
  import UUID
  require Logger

  defp defaultEdge, do: %{name: String.to_atom(UUID.uuid4), source: nil, target: nil, value: nil, valid: false, filter: fn(x)-> true end}

  def new(fieldUpdates), do: Enum.into(fieldUpdates, defaultEdge)

  def doAdd(graph, edge), do: :digraph.add_edge graph, edge.name, edge.source, edge.target, edge 
  def doDel(graph, edge), do: :digraph.del_edge graph, edge.name 
  def doUpdate(graph, edge, changes) do
    # changes is a keyword list
    new_edge = 
      Enum.reduce changes, edge, fn
        ({:value, ch_value}, acc) -> acc |> Map.put(:value, ch_value) |> Map.put(:valid, true)
        ({ch_key, ch_value}, acc) -> acc |> Map.put(ch_key, ch_value)
      end
    Edge.doDel graph, edge
    Edge.doAdd graph, new_edge
  end

  def add(edge),              do: %{op: &Edge.doAdd/2, args: [edge]}
  def del(edge),              do: %{op: &Edge.doDel/2, args: [edge]}
  def update(edge, changes),  do: %{op: &Edge.doUpdate/3, args: [edge, changes]}
  def updates(edges, changes) do
    for e <- edges, do: Edge.update e, changes
  end
end
