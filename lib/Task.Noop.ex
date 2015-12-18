defmodule Task.Noop do
  def run(_graph, _taskname) do
    []
  end
end

