defmodule Tsk.Setup do
  @doc """
  setup functions that need to be done before running the rest of the tsks
  """

  import Tskr.Util

  def run(_graph, _tskname, _inputs, outputs) do
    {:ok, _} = Tskr.MongoPool.start_link(database: "cmdb", hostname: "qain1ansred.qa.local")
    outputs |> Edge.updates(value: :go)
  end
end


