defmodule Tskr.MongoPool do
  use Mongo.Pool, 
    name: __MODULE__, 
    adapter: Mongo.Pool.Poolboy,
    hostname: "qain1ansred.qa.local"
end

