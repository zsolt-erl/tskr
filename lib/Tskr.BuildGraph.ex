defmodule Tskr.BuildGraph do
  import Tskr.Util

  def go do
    updates = [
      addTask(:start, Task.Noop),
      addTask(:stop, Task.Stop),
      addTask(:fib, Task.Fib),
      addEdge(:start, :fib, name: :edgein, value: 7),
      addEdge(:fib, :stop, name: :edgeout)
      ]
    Tskr.Store.update updates
  end
end
