require "cassandra_record"

connection = Cassandra.cluster.connect
connection.execute "DROP KEYSPACE IF EXISTS cassandra_record"
connection.execute "CREATE KEYSPACE cassandra_record WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 }"

CassandraRecord::Base.connection_pool = ConnectionPool.new(size: 1, timeout: 5) do
  Cassandra.cluster.connect("cassandra_record")
end

CassandraRecord::Base.execute <<CQL
  CREATE TABLE posts(
    user TEXT,
    domain TEXT,
    id TIMEUUID,
    message TEXT,
    timestamp TIMESTAMP,
    PRIMARY KEY((user, domain), id)
  )
CQL

class Post < CassandraRecord::Base
  column :user, :text, partition_key: true
  column :domain, :text, partition_key: true
  column :id, :timeuuid, clustering_key: true
  column :message, :text
  column :timestamp, :timestamp

  before_create do
    self.timestamp ||= Time.now
    self.id ||= generate_timeuuid(timestamp)
  end
end

CassandraRecord::Base.execute <<CQL
  CREATE TABLE test_logs(
    date DATE,
    bucket INT,
    id TIMEUUID,
    query TEXT,
    username TEXT,
    timestamp TIMESTAMP,
    PRIMARY KEY((date, bucket), id)
  )
CQL

class TestLog < CassandraRecord::Base
  column :date, :date, partition_key: true
  column :bucket, :int, partition_key: true
  column :id, :timeuuid, clustering_key: true
  column :query, :text
  column :username, :text
  column :timestamp, :timestamp

  validates_presence_of :timestamp

  def self.bucket_for(id)
    Digest::SHA1.hexdigest(id.to_s)[0].to_i(16) % 8
  end

  before_create do
    self.id = generate_timeuuid(timestamp)

    self.date = id.to_date.strftime("%F")
    self.bucket = self.class.bucket_for(id)
  end
end

class TestLogWithContext < TestLog
  def self.table_name
    "test_logs"
  end

  validates_presence_of :username, on: :create
  validates_presence_of :query, on: :update
end

RSpec.configure do |config|
  config.before do
    CassandraRecord::Base.execute <<~CQL
      DROP TABLE IF EXISTS schema_migrations
    CQL

    TestLog.delete_in_batches
    Post.delete_in_batches
  end
end
