defmodule Tsk do
  import UUID

  defstruct name: nil, code: Tsk.Noop

  # needed to create new tsks with different default names
  def new(fieldUpdates), do: Map.merge(  %{%Tsk{} | name: String.to_atom(UUID.uuid4)}, Enum.into(fieldUpdates, %{}))

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

  # def add(tsk), do: %{op: :tsk_add, tsk: tsk}
  # def del(tsk), do: %{op: :tsk_del, tsk: tsk}
  # def update(tsk, args), do: %{op: :tsk_update, tsk: tsk, args: args}

end


defmodule Edge do
  import UUID

  def defaultFilter(x), do: true

  defstruct name: nil, source: nil, target: nil, value: nil, valid: false, filter: &Edge.defaultFilter/1

  def new(fieldUpdates), do: Map.merge( %{%Edge{} | name: String.to_atom(UUID.uuid4)}, Enum.into(fieldUpdates, %{}))

  def doAdd(graph, edge), do: :digraph.add_edge graph, edge.name, edge.source, edge.target, edge 
  def doDel(graph, edge), do: :digraph.del_edge graph, edge.name 
  def doUpdate(graph, edge, changes) do
    # changes is a keyword list
    new_edge = 
      Enum.reduce changes, edge, fn
        ({:value, ch_value}, acc) -> acc |> Map.put(:value, ch_value) |> Map.put(:valid, true)
        ({ch_key, ch_value}, acc) -> acc |> Map.put(ch_key, ch_value)
      end
    Edge.doAdd graph, new_edge
  end

  def add(edge),              do: %{op: &Edge.doAdd/2, args: [edge]}
  def del(edge),              do: %{op: &Edge.doDel/2, args: [edge]}
  def update(edge, changes),  do: %{op: &Edge.doUpdate/3, args: [edge, changes]}
  def updates(edges, changes) do
    for e <- edges, do: Edge.update e, changes
  end


  # def add(edge), do: %{op: :edge_add, edge: edge}
  # def del(edge), do: %{op: :edge_del, edge: edge}
  # def update(edge, args), do: %{op: :edge_update, edge: edge, args: args}

end
