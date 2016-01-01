defmodule Task do
  import UUID

  defstruct name: String.to_atom UUID.uuid4, code: nil
end

defmodule Edge do
  defstruct :name, :source, :target, :value, :valid, filter: 
