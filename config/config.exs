use Mix.Config

config :tskr,
  nodes: [
    %{:name => :fib, :state => %{code: Task.Fib}},
    %{:name => :start,  :state => %{code: Task.Noop}},
    %{:name => :stop, :state => %{code: Task.Stop}}
    ],
  edges: [
    %{:name => :edgein, :label => %{valid: true, value: 20}, :source => :start, :target => :fib}, 
    %{:name => :edgeout, :label => %{valid: false, value: nil}, :source => :fib, :target => :stop} 
    ]

config :logger, :console, level: :info,
  format: "\n#{__MODULE__} $time [$level] $metadata$message",
  metadata: [:user_id, :mod]


# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
#     config :tskr, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:tskr, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"

