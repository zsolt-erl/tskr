defmodule Tskr.Spec do
  def addTask(name, code \\ Tskr.Noop), do:  %{op: :add_task, name: name, state: %{code: code}}
  def delTask(name), do: %{op: :delete_task, name: name}
  def updateTask(name, new_state), do: %{op: :update_task, name: name, new_state: new_state}

  @doc """
  args can be:
  name, value, filter
  filter is an expression given as a string that can be evalutated (eg. "{:failed, _}" or "true")
  """
  def addEdge(source, target, args \\ []) do
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
    %{op: :add_edge, name: name, source: source, target: target, state: state}
  end
  def delEdge(name), do: %{op: :delete_edge, name: name}
  def updateEdge(name, new_state), do: %{op: :update_edge, name: name, new_state: new_state}
end
