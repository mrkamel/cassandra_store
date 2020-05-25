require "cassandra"
require "connection_pool"
require "active_model"
require "active_support/all"
require "hooks"

require "cassandra_store/version"
require "cassandra_store/base"
require "cassandra_store/relation"
require "cassandra_store/schema_migration"
require "cassandra_store/migration"
require "cassandra_store/railtie" if defined?(Rails)

module CassandraStore
  class RecordInvalid < StandardError; end
  class RecordNotPersisted < StandardError; end
  class UnknownType < StandardError; end
end
