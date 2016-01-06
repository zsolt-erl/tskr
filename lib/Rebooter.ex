defmodule Rebooter do
  import Tskr.Util

  # def build do
  #   start    = %Tsk{name: :start, code: Tsk.Noop}
  #   stop     = %Tsk{name: :stop, code: Tsk.Stop}
  #   setup    = %Tsk{name: :setup, code: Tsk.Setup}
  #   rebooter = %Tsk{name: :rebooter, code: Tsk.Rebooter}
  #   park     = %Tsk{name: :park, code: Tsk.Noop}
  #   parkloop = %Edge{source: :park, target: :park, value: true, valid: true}

  #   updates = [
  #     Tsk.add(start),
  #     park ~> park,
  #     Edge.add(parkloop),

  #     true ~>> setup,
  #     setup ~> rebooter,
  #     rebooter ~> stop
  #     ]
  #   Tskr.Store.update updates
  # end

  def buildFib do
    start = Tsk.new name: :start, code: Tsk.Noop
    stop  = Tsk.new name: :stop, code: Tsk.Stop
    park  = Tsk.new name: :park, code: Tsk.Noop
    parkloop = Edge.new source: :park, target: :park, value: true, valid: true

    fib   = Tsk.new code: Tsk.Fib

    initial_graph = [ 
      Tsk.add(start),
      Tsk.add(stop),
      Tsk.add(park),
      Edge.add(parkloop),

      Tsk.add(fib),

      7 ~>> fib,
      fib ~> stop
    ]
    Tskr.Store.update initial_graph
  end

  def go do
    send Tskr.Scheduler, :start
  end
end


