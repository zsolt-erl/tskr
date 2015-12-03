defmodule Tskr.RunnerSup do
  use Supervisor
  require Logger

  def start_link(args, opts) do
    Logger.info "#{__MODULE__} start_link args: #{inspect args}"
    Logger.info "#{__MODULE__} start_link opts: #{inspect opts}"
    Supervisor.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    Logger.info "#{__MODULE__} Init started: #{inspect args}"
    children = [ 
      worker(Tskr.Runner, []) 
    ]
    supervise(children, [strategy: :simple_one_for_one])
  end
end

