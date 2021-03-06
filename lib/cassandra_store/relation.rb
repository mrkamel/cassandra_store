class CassandraStore::Relation
  attr_accessor :target, :where_values, :where_cql_values, :order_values, :limit_value, :distinct_value, :select_values

  def initialize(target:)
    self.target = target
  end

  def all
    fresh
  end

  def where(hash = {})
    fresh.tap do |relation|
      relation.where_values = (relation.where_values || []) + [hash]
    end
  end

  def where_cql(string, args = {})
    fresh.tap do |relation|
      str = string

      args.each do |key, value|
        str.gsub!(":#{key}", target.quote_value(value))
      end

      relation.where_cql_values = (relation.where_cql_values || []) + [str]
    end
  end

  def update_all(string_or_hash)
    if string_or_hash.is_a?(Hash)
      target.execute("UPDATE #{target.quote_table_name target.table_name} SET #{string_or_hash.map { |column, value| "#{target.quote_column_name column} = #{target.quote_value value}" }.join(", ")} #{where_clause}")
    else
      target.execute("UPDATE #{target.quote_table_name target.table_name} SET #{string_or_hash} #{where_clause}")
    end

    true
  end

  def order(hash = {})
    fresh.tap do |relation|
      relation.order_values = (relation.order_values || {}).merge(hash)
    end
  end

  def limit(n)
    fresh.tap do |relation|
      relation.limit_value = n
    end
  end

  def first(n = 1)
    result = limit(n).to_a

    return result.first if n == 1

    result
  end

  def distinct
    fresh.tap do |relation|
      relation.distinct_value = true
    end
  end

  def select(*columns)
    fresh.tap do |relation|
      relation.select_values = (relation.select_values || []) + columns
    end
  end

  def find_each(**kwargs)
    return enum_for(:find_each, **kwargs) unless block_given?

    find_in_batches(**kwargs) do |batch|
      batch.each do |record|
        yield(record)
      end
    end
  end

  def find_in_batches(batch_size: 1_000)
    return enum_for(:find_in_batches, batch_size: batch_size) unless block_given?

    each_page "SELECT #{select_clause} FROM #{target.quote_table_name target.table_name} #{where_clause} #{order_clause} #{limit_clause}", page_size: batch_size do |result|
      records = []

      result.each do |row|
        records << if select_values.present?
                     row
                   else
                     load_record(row)
                   end
      end

      yield(records) unless records.empty?
    end
  end

  def delete_all
    target.execute("DELETE FROM #{target.quote_table_name target.table_name} #{where_clause}")

    true
  end

  def delete_in_batches
    find_in_batches do |records|
      records.each do |record|
        where_clause = target.key_columns.map { |column, _| "#{target.quote_column_name column} = #{target.quote_value record.read_raw_attribute(column)}" }.join(" AND ")

        target.execute "DELETE FROM #{target.quote_table_name target.table_name} WHERE #{where_clause}"
      end
    end

    true
  end

  def count
    cql = "SELECT COUNT(*) FROM #{target.quote_table_name target.table_name} #{where_clause}"

    target.execute(cql).first["count"]
  end

  def to_a
    @records ||= find_each.to_a
  end

  private

  def load_record(row)
    target.new.tap do |record|
      record.persisted!

      row.each do |key, value|
        record.write_raw_attribute(key, value)
      end
    end
  end

  def fresh
    dup.tap do |relation|
      relation.instance_variable_set(:@records, nil)
    end
  end

  def each_page(cql, page_size:)
    result = target.execute(cql, page_size: page_size)

    while result
      yield result

      result = result.next_page
    end
  end

  def select_clause
    "#{distinct_value ? "DISTINCT" : ""} #{select_values.presence ? select_values.join(", ") : "*"}"
  end

  def where_clause
    return if where_values.blank? && where_cql_values.blank?

    constraints = []

    Array(where_values).each do |hash|
      hash.each do |column, value|
        constraints << if value.is_a?(Array) || value.is_a?(Range)
                         "#{target.quote_column_name column} IN (#{value.to_a.map { |v| target.quote_value v }.join(", ")})"
                       else
                         "#{target.quote_column_name column} = #{target.quote_value value}"
                       end
      end
    end

    constraints += Array(where_cql_values)

    "WHERE #{constraints.join(" AND ")}"
  end

  def order_clause
    (order_values.presence ? "ORDER BY #{order_values.map { |column, value| "#{target.quote_column_name column} #{value}" }.join(", ")}" : "").to_s
  end

  def limit_clause
    (limit_value ? "LIMIT #{limit_value.to_i}" : "").to_s
  end
end
