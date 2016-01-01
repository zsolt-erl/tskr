defmodule Tskr do
  use Application

  defp runner_pool_name, do: :runner_pool


  def start(_type, _args) do
    IO.puts("123"+"5")
    IO.puts((123~>5, 42))

    import Supervisor.Spec, warn: false

    poolboy_config = [
      {:name, {:local, runner_pool_name()}},
      {:worker_module, Tskr.Runner},
      {:size, 5},
      {:max_overflow, 2}
    ]

    children = [
      worker(Tskr.Store, [[], [name: Tskr.Store]]),
      worker(Tskr.Scheduler, [[], [name: Tskr.Scheduler]]),
      :poolboy.child_spec(runner_pool_name(), poolboy_config, [])
      #supervisor(Tskr.RunnerSup, [[:arg42], [name: Tskr.RunnerSup]])
    ]

    opts = [strategy: :one_for_one, name: Tskr.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
