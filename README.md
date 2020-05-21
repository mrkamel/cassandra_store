[![Build Status](https://secure.travis-ci.org/mrkamel/cassandra-record.png?branch=master)](http://travis-ci.org/mrkamel/cassandra-record)

# CassandraRecord

CassandraRecord is a fun to use ORM for Cassandra with a chainable,
ActiveRecord like DSL for querying, inserting, updating and deleting records
plus built-in migration support. It is built on-top of the cassandra-driver
gem, using its built-in automated paging what is drastically reducing the
complexity of the code base.

## Install

Add this line to your application's Gemfile:

    gem 'cassandra-record'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cassandra-record

# Usage

## Connecting

First and foremost, you need to connect to your cassandra cluster like so:

```ruby
CassandraRecord::Base.configure(
  hosts: ["127.0.0.1"],
  keyspace: "my_keyspace",
  cluster_settings: { consistency: :quorum }
)
```

When using rails, you want to do that in an initializer. If you do not yet have
a keyspace, you additionally want to pass `replication` settings:

```ruby
CassandraRecord::Base.configure(
  hosts: ["127.0.0.1"],
  keyspace: "my_keyspace",
  cluster_settings: { consistency: :quorum },
  replication: { class: 'SimpleStrategy', replication_factor: 1 }
)
```

Afterwards, you can create/drop the specified keyspace:

```ruby
rake cassandra:keyspace:create
rake cassandra:keyspace:drop
```

## Migrations

If you are on rails and you don't have any tables yet, you can add migrations
now. There is no generator yet, so you have to create them manually:

```ruby
# cassandra/migrate/1589896040_create_posts.rb

class CreatePosts < CassandraRecord::Migration
  def up
    execute <<-CQL
      CREATE TABLE posts (
        user TEXT,
        domain TEXT,
        id TIMEUUID,
        message TEXT,
        PRIMARY KEY ((user, domain), id)
      )
    CQL
  end

  def down
    execute 'DROP TABLE posts'
  end
end
```

Afterwards, simply run `rake cassandra:migrate`.

## Models

Creating models couldn't be easier:

```ruby
class Post < CassandraRecord::Base
  column :user, :text, partition_key: true
  column :domain, :text, partition_key: true
  column :id, :timeuuid, clustering_key: true
  column :message, :text

  validates_presence_of :user, :domain, :message

  before_create do
    self.id ||= generate_timeuuid
  end
end
```

Let's check this out in detail:

```ruby
  column :user, :text, partition_key: true
  column :domain, :text, partition_key: true
```

tells CassandraRecord that your partition key is comprised of the `user` column
as well as the `domain` column. For more information regarding partition keys
and the data model of cassandra, please check out the cassandra docs. Afterwards,
the clustering/sorting key is specified via:

```ruby
column :id, :timeuuid, clustering_key: true
```

The `id` is assigned here:

```ruby
  self.id ||= generate_timeuuid
```

Please note, CassandraRecord never auto-assigns any values for you, but you
have to assign them. You can pass a timestamp to `generate_timeuuid` as well:

```ruby
  generate_timeuuid(Time.now)
```

This is desirable when you have timestamp columns as well and you want them
to match with your timeuuid key.

Similarly, when using `UUID` instead of `TIMEUUID` you have to use
`generate_uuid` instead.

In addition, you can of course use all kinds of validations, hooks, etc.

## Querying

The interface for dealing with records and querying them is very similar
to the interface of `ActiveRecord`:

```ruby
Post.create!(user: "mrkamel", ...)
Post.create(...)
Post.new(...).save
Post.new(...).save!
Post.first.delete
Post.first.destroy
```

CassandraRecord supports comprehensive query methods in a chainable way:

* `all`

```ruby
  Post.all
```

* `where`

```ruby
  Post.where(user: "mrkamel", domain: "example.com")
```

* `where_cql`

```ruby
  Post.where_cql("user = :user", user: "mrkamel")
```

* `limit`

```ruby
  Post.where(...).limit(10)
```

* `order`

```ruby
  Post.where(...).order(id: "asc")
```

* `distinct`

```ruby
  Post.select(:user, :domain).distinct
```

* `select`

```ruby
  Post.select(:user, :domain)
```

Please note, when using `select` in the end an array of hashes will be returned
instead of an array of `Post` objects.

* `count`

```ruby
  Post.where(...).count
```

* `first`

```ruby
  Post.where(...).first
```

* `find_each`

```ruby
  Post.where(...).find_each(batch_size: 100) do |post|
    # ...
  end
```

* `find_in_batches`

```ruby
  Post.where(...).find_in_batches(batch_size: 100) do |batch|
    # ...
  end
```

* `update_all`

```ruby
  Post.where(...).update_all("message = 'test'")
  Post.where(...).update_all(message: "test")
```

* `delete_all`

```ruby
  Post.where(...).delete_all
```

Please note, that `delete_in_batches` will run `find_in_batches` iteratively
and then delete each batch. When dealing with large amounts of records to
delete you usually want to use `delete_in_batches` instead of `delete_all`, as
`delete_all` can time out.

* `delete_in_batches`

```ruby
  Post.where(...).delete_in_batches
```

Again, please note, that `delete_in_batches` will run `find_in_batches` iteratively
and then delete each batch. When dealing with large amounts of records to
delete you usually want to use `delete_in_batches` instead of `delete_all`, as
`delete_all` can time out.

* `truncate_table`

```ruby
  Post.truncate_table
```

Deletes all records from the table. This is much faster than `delete_all` or
`delete_in_batches`.  However, it is not chainable, such that your only option
is to remove all records from the table.

## Semantic Versioning

CassandraRecord is using Semantic Versioning: [SemVer](http://semver.org/)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

