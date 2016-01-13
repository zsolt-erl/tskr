defmodule Tskr do
  use Application

  @redis_pool_name :redix_pool
  @redis_conn_params host: "localhost"  #,password: "secret"
  @runner_pool_name :runner_pool

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    poolboy_config_redis = [
      name: {:local, @redis_pool_name},
      worker_module: Redix,
      size: 5,
      max_overflow: 2
    ]

    poolboy_config_runner = [
      name: {:local, @runner_pool_name},
      worker_module: Tskr.Runner,
      size: 5,
      max_overflow: 2
    ]

    children = [
      worker(Tskr.Store, [[], [name: Tskr.Store]]),
      worker(Tskr.Scheduler, [[], [name: Tskr.Scheduler]]),
      :poolboy.child_spec(@runner_pool_name, poolboy_config_runner, []),
      :poolboy.child_spec(@redis_pool_name, poolboy_config_redis, @redis_conn_params)
      #supervisor(Tskr.RunnerSup, [[:arg42], [name: Tskr.RunnerSup]])
    ]

    opts = [strategy: :one_for_one, name: Tskr.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
