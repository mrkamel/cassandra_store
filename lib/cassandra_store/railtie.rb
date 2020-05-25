module CassandraStore
  class Railtie < Rails::Railtie
    rake_tasks do
      load "cassandra_store/tasks/cassandra.rake"
    end
  end
end
