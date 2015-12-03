defmodule Test do
  def r do
    m = %{field2: 12, field1: 44}
    inspect m
    case m do
      %{field1: 44, field2: f2} ->
        IO.puts f2
      _ ->
        IO.puts "no match"
    end
  end
end

