defmodule Tsk.Fib do
  import Tskr.Util

  def run(graph, myself, inputs \\ [], outputs \\ []) do
    input_val = Enum.at(inputs, 0).value
    cond do 
      input_val === 0 or input_val === 1 ->
        # output equals the original input
        outputs |> Edge.updates( value: input_val )

      true ->
        # new tsks
        fib1 = Tsk.new code: Tsk.Fib
        fib2 = Tsk.new code: Tsk.Fib
        sum  = Tsk.new code: Tsk.Sum

        # calculate inputs for new Fib tsks
        fib1_input = input_val - 1
        fib2_input = input_val - 2

        [
          Tsk.del(myself),
          inputs |> Edge.updates( target: :park ),

          Tsk.add(fib1),
          Tsk.add(fib2),
          Tsk.add(sum),

          fib1_input ~>> fib1,
          fib2_input ~>> fib2,

          fib1 ~> sum,
          fib2 ~> sum,

          outputs |> Edge.updates( source: sum.name )
        ]
    end
  end
end


