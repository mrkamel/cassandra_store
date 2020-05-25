namespace :cassandra do
  namespace :keyspace do
    desc "Drop the keyspace"
    task drop: :environment do
      CassandraStore::Base.logger.level = Logger::DEBUG
      CassandraStore::Base.drop_keyspace(if_exists: true)
    end

    desc "Create the keyspace"
    task create: :environment do
      CassandraStore::Base.logger.level = Logger::DEBUG
      CassandraStore::Base.create_keyspace(if_not_exists: true)
    end
  end

  namespace :migrate do
    desc "Run a specific up-migration"
    task up: :environment do
      raise "No VERSION specified" unless ENV["VERSION"]

      CassandraStore::Base.logger.level = Logger::DEBUG

      CassandraStore::SchemaMigration.create_table(if_not_exists: true)
      CassandraStore::Migration.up Rails.root.join("cassandra/migrate"), ENV["VERSION"]
    end

    desc "Run a specific down-migration"
    task down: :environment do
      raise "No VERSION specified" unless ENV["VERSION"]

      CassandraStore::Base.logger.level = Logger::DEBUG

      CassandraStore::SchemaMigration.create_table(if_not_exists: true)
      CassandraStore::Migration.down Rails.root.join("cassandra/migrate"), ENV["VERSION"]
    end
  end

  desc "Run pending migrations"
  task migrate: :environment do
    CassandraStore::Base.logger.level = Logger::DEBUG

    CassandraStore::SchemaMigration.create_table(if_not_exists: true)
    CassandraStore::Migration.migrate Rails.root.join("cassandra/migrate")
  end
end
