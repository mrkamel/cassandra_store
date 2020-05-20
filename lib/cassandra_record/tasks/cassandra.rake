namespace :cassandra do
  namespace :migrate do
    desc "Run a specific up-migration"
    task up: :environment do
      raise "No VERSION specified" unless ENV["VERSION"]

      CassandraRecord::Base.logger.level = Logger::DEBUG

      CassandraRecord::SchemaMigration.create_table(if_not_exists: true)
      CassandraRecord::Migration.up Rails.root.join("cassandra/migrate"), ENV["VERSION"]
    end

    desc "Run a specific down-migration"
    task down: :environment do
      raise "No VERSION specified" unless ENV["VERSION"]

      CassandraRecord::Base.logger.level = Logger::DEBUG

      CassandraRecord::SchemaMigration.create_table(if_not_exists: true)
      CassandraRecord::Migration.down Rails.root.join("cassandra/migrate"), ENV["VERSION"]
    end
  end

  desc "Run pending migrations"
  task migrate: :environment do
    CassandraRecord::Base.logger.level = Logger::DEBUG

    CassandraRecord::SchemaMigration.create_table(if_not_exists: true)
    CassandraRecord::Migration.migrate Rails.root.join("cassandra/migrate")
  end
end
