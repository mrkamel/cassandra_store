module CassandraRecord
  class Railtie < Rails::Railtie
    rake_tasks do
      load "cassandra_record/tasks/cassandra.rake"
    end
  end
end
