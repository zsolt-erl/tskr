defmodule Rebooter do
  import Tskr.Util

  def build do
    updates = [
      addTask(:start, Task.Noop),
      addTask(:stop, Task.Stop),
      addTask(:setup, Task.Setup),
      addTask(:rebooter, Task.Rebooter),
      addEdge(:start, :setup, name: :edgein, value: true),
      addEdge(:setup, :rebooter, name: :edgestart),
      addEdge(:rebooter, :stop, name: :edgeout),
      addTask(:park, Task.Noop),
      addEdge(:park, :stop, value: true)
      ]
    Tskr.Store.update updates
  end

  def go do
    send Tskr.Scheduler, :start
  end
end


