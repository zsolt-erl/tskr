defmodule Operators do

  defmacro a + b do
    quote do
      to_string(unquote(a)) <> to_string(unquote(b))
    end
  end

  def a ~> b do
    addedge(
    IO.inspect "c argument: #{inspect c}"
    a - b
  end

  def addedge(s, e, args \\ []) do
    IO.inspect "s: #{s}, e: #{e}, args: #{args}"
  end
end
