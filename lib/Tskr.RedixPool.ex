defmodule Tskr.RedixPool do
  
  def command(cmd) do
    :poolboy.transaction(:redix_pool, &Redix.command(&1, cmd))
  end
  
  def pipeline(cmds) do
    :poolboy.transaction(:redix_pool, &Redix.pipeline(&1, cmds))
  end

end

