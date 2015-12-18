defmodule Task.Fib do
  import Tskr.Util

  def run(graph, taskname, inputs \\ [], outputs \\ []) do
    input_val = Enum.at(inputs, 0).value
    cond do 
      input_val === 0 or input_val === 1 ->
        # output equals the original input
        [ updateEdgeValue(hd(outputs).name, input_val) ]

      true ->
        # replace current task with new tasks
        #####################################

        # store original input and output edges
        ein = getInEdges graph, taskname
        eout = getOutEdges graph, taskname

        # generate names for new tasks
        fib1 = [generateTaskName(), Task.Fib]
        fib2 = [generateTaskName(), Task.Fib]
        sum  = [generateTaskName(), Task.Sum]

        # calculate inputs for new Fib tasks
        fib1_input = input_val - 1
        fib2_input = input_val - 2

        # create the replacement subgraph
        replaceTask(graph, taskname, %{ 
          fib1 => sum,
          fib2 => sum,
          {fib1_input} => fib1,
          {fib2_input} => fib2
        })
        # connect original input edges to :stop (these are not needed anymore)
        ++ (ein |> updateTarget(:park)) 
        # connect original output edge to the Sum task
        ++ (eout |> updateSource(hd(sum)))
    end
  end
end


