defmodule Tskr.Viz do
  
  def show(graph) do
    :io.format "~n===================================================~n"
    :io.format "graph {~n"
    for vertname <- :digraph.vertices(graph) do
      {^vertname, label} = :digraph.vertex graph, vertname
      :io.format("  ~p [label=\"~p\"];~n", [vertname, label.code])
    end
    for edgename <- :digraph.edges(graph) do
      {^edgename, from, to, label} = :digraph.edge graph, edgename
      :io.format("  ~p -> ~p [label=\"~p\"];~n", [from, to, label.value])
    end
    :io.format "}"
    :io.format "~n===================================================~n"
  end

  defp to_str(term) do
    :io_lib.format("~p", [term])
    |> List.flatten
    |> to_string
    |> String.replace( ~r/[{}, ]/, "" )
  end
  

  def tuple_to_str(term) when is_tuple(term) do
    List.flatten(for t <- Tuple.to_list(term), do: :io_lib.format("~p", [t]))
  end
  def tuple_to_str(term) do
    term
  end

  def write(graph) do
    {:ok, file} = File.open "viz/viz.dot", [:append]

    IO.write file, "\ndigraph {\n"

    for vertname <- :digraph.vertices(graph) do
      {^vertname, label} = :digraph.vertex graph, vertname
      vertname_str = to_str vertname
      #line = List.flatten :io_lib.format("  \"~s\" [label=\"~s\"];~n", [vertname_str, label.code])
      line = List.flatten :io_lib.format("  \"~s\" [label=\"~s\"];~n", [vertname_str, vertname_str])
      IO.write file, line
    end
    for edgename <- :digraph.edges(graph) do
      {^edgename, from, to, label} = :digraph.edge graph, edgename
      line = List.flatten :io_lib.format("  \"~s\" -> \"~s\" [label=\"~p\"];~n", [to_str(from), to_str(to), label.value])
      IO.write file, line
    end

    IO.write file, "}\n"
    File.close file
  end
end

