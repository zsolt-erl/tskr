defmodule Task.Setup do
  @doc """
  setup functions that need to be done before running the rest of the tasks
  """

  import Tskr.Util

  def run(_graph, _taskname, _inputs, outputs) do
    {:ok, _} = Tskr.MongoPool.start_link(database: "cmdb", hostname: "qain1ansred.qa.local")
    taskout(outputs, :go)
  end
end


