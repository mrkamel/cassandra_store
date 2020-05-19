require File.expand_path("../spec_helper", __dir__)

class TestRecord < CassandraRecord::Base
  column :text, :text
  column :boolean, :boolean
  column :int, :int
  column :bigint, :bigint
  column :date, :date
  column :timestamp, :timestamp
  column :timeuuid, :timeuuid
  column :uuid, :uuid
end

RSpec.describe CassandraRecord::Base do
  describe ".new" do
    it "assigns the specified attributes" do
      test_log = TestLog.new(timestamp: "2016-11-01 12:00:00", username: "username")

      expect(Time.parse("2016-11-01 12:00:00").utc.round(3)).to eq(test_log.timestamp)
      expect(test_log.username).to eq("username")
    end
  end

  describe "#assign" do
    it "assigns the specified attributes" do
      test_log = TestLog.new
      test_log.assign(timestamp: "2016-11-01 12:00:00", username: "username")

      expect(Time.parse("2016-11-01 12:00:00").utc.round(3)).to eq(test_log.timestamp)
      expect(test_log.username).to eq("username")
    end

    it "raises an ArgumentError when re-assigning a key attribute" do
      test_log = TestLog.create!(timestamp: Time.parse("2016-11-01 12:00:00"))

      expect(test_log.persisted?).to eq(true)
      expect { test_log.assign(date: Date.parse("2016-11-02")) }.to raise_error(ArgumentError)
    end
  end

  describe "#attributes" do
    it "returns the attributes as a hash" do
      test_log = TestLog.new(timestamp: "2016-11-01 12:00:00", username: "username")

      expect(test_log.attributes).to eq(
        date: nil,
        bucket: nil,
        id: nil,
        query: nil,
        username: "username",
        timestamp: Time.parse("2016-11-01 12:00:00").utc.round(3)
      )
    end
  end

  describe ".cast_value" do
    it "casts string attributes" do
      expect(TestRecord.new(text: "text").text).to eq("text")
      expect(TestRecord.new(text: 1).text).to eq("1")
    end

    it "casts boolean attributes" do
      expect(TestRecord.new(boolean: true).boolean).to eq(true)
      expect(TestRecord.new(boolean: false).boolean).to eq(false)
      expect(TestRecord.new(boolean: 1).boolean).to eq(true)
      expect(TestRecord.new(boolean: 0).boolean).to eq(false)
      expect(TestRecord.new(boolean: "1").boolean).to eq(true)
      expect(TestRecord.new(boolean: "0").boolean).to eq(false)
      expect(TestRecord.new(boolean: "true").boolean).to eq(true)
      expect(TestRecord.new(boolean: "false").boolean).to eq(false)
      expect { TestRecord.new(boolean: :other).boolean }.to raise_error(ArgumentError)
    end

    it "casts int attributes" do
      expect(TestRecord.new(int: 1).int).to eq(1)
      expect(TestRecord.new(int: "1").int).to eq(1)
      expect(TestRecord.new(int: 1.0).int).to eq(1)
      expect { TestRecord.new(int: :other).int }.to raise_error(TypeError)
    end

    it "casts bigint attributes" do
      expect(TestRecord.new(bigint: 1).bigint).to eq(1)
      expect(TestRecord.new(bigint: "1").bigint).to eq(1)
      expect(TestRecord.new(bigint: 1.0).bigint).to eq(1)
      expect { TestRecord.new(bigint: :other).int }.to raise_error(TypeError)
    end

    it "casts date attributes" do
      expect(TestRecord.new(date: Date.new(2016, 11, 1)).date).to eq(Date.new(2016, 11, 1))
      expect(TestRecord.new(date: "2016-11-01").date).to eq(Date.new(2016, 11, 1))
      expect { TestRecord.new(date: :other).date }.to raise_error(ArgumentError)
    end

    it "casts timestamp attributes" do
      expect(TestRecord.new(timestamp: Time.parse("2016-11-01 12:00:00")).timestamp).to eq(Time.parse("2016-11-01 12:00:00").utc.round(3))
      expect(TestRecord.new(timestamp: "2016-11-01 12:00:00").timestamp).to eq(Time.parse("2016-11-01 12:00:00").utc.round(3))
      expect(TestRecord.new(timestamp: Time.parse("2016-11-01 12:00:00").to_i).timestamp).to eq(Time.parse("2016-11-01 12:00:00").utc.round(3))
      expect { TestRecord.new(timestamp: :other).timestamp }.to raise_error(ArgumentError)
    end

    it "casts timeuuid attributes" do
      expect(TestRecord.new(timeuuid: Cassandra::TimeUuid.new("1ce29e82-b2ea-11e6-88fa-2971245f69e1")).timeuuid).to eq(Cassandra::TimeUuid.new("1ce29e82-b2ea-11e6-88fa-2971245f69e1"))
      expect(TestRecord.new(timeuuid: "1ce29e82-b2ea-11e6-88fa-2971245f69e2").timeuuid).to eq(Cassandra::TimeUuid.new("1ce29e82-b2ea-11e6-88fa-2971245f69e2"))
      expect(TestRecord.new(timeuuid: 38_395_057_947_756_324_226_486_198_980_982_041_059).timeuuid).to eq(Cassandra::TimeUuid.new(38_395_057_947_756_324_226_486_198_980_982_041_059))
      expect { TestRecord.new(timeuuid: :other).timeuuid }.to raise_error(ArgumentError)
    end

    it "casts uuid attributes" do
      expect(TestRecord.new(uuid: Cassandra::Uuid.new("b9af7b9b-9317-43b3-922e-fe303f5942c1")).uuid).to eq(Cassandra::Uuid.new("b9af7b9b-9317-43b3-922e-fe303f5942c1"))
      expect(TestRecord.new(uuid: "b9af7b9b-9317-43b3-922e-fe303f5942c1").uuid).to eq(Cassandra::Uuid.new("b9af7b9b-9317-43b3-922e-fe303f5942c1"))
      expect(TestRecord.new(uuid: 13_466_612_472_233_423_808_722_080_080_896_418_394).uuid).to eq(Cassandra::Uuid.new(13_466_612_472_233_423_808_722_080_080_896_418_394))
      expect { TestRecord.new(uuid: :other).uuid }.to raise_error(ArgumentError)
    end
  end

  describe "#save" do
    it "returns false when validation fails" do
      test_log = TestLog.new

      expect(test_log.save).to eq(false)
    end

    it "does not persist the record when validation fails" do
      test_log = TestLog.new

      expect { test_log.save }.not_to change { TestLog.count }
    end

    it "adds the errors when validation fails" do
      test_log = TestLog.new
      test_log.save

      expect(test_log.errors[:timestamp]).to include("can't be blank")
    end

    it "persists the record" do
      test_log = TestLog.new(timestamp: Time.parse("2016-11-01 12:00:00"), username: "username")

      expect { test_log.save }.to change { TestLog.count }.by(1)
      expect(test_log.persisted?).to eq(true)

      reloaded_test_log = TestLog.where(date: test_log.date, bucket: test_log.bucket, id: test_log.id).first

      expect(reloaded_test_log.attributes).to eq(test_log.attributes)
    end

    it "executes the hooks" do
      test_log = TestLog.new(timestamp: Time.parse("2016-11-01 12:00:00"), username: "username")
      test_log.save

      expect(test_log.date).to eq(Date.parse("2016-11-01"))
      expect(test_log.username).to eq("username")
      expect(test_log.bucket).to be_present
      expect(test_log.id).to be_present
    end
  end

  describe "#save!" do
    it "raises an error if validation fails" do
      test_log = TestLog.new

      expect { test_log.save! }.to raise_error(CassandraRecord::RecordInvalid)
    end

    it "does not persist the record if validation fails" do
      test_log = TestLog.new

      expect { test_log.save! rescue nil }.not_to change { TestLog.count }
    end

    it "returns true when the record can be persisted" do
      test_log = TestLog.new(timestamp: Time.parse("2016-11-01 12:00:00"))

      expect { test_log.save! rescue nil }.to change { TestLog.count }.by(1)
    end

    it "persists the record" do
      test_log = TestLog.new(timestamp: Time.parse("2016-11-01 12:00:00"), username: "username")

      expect { test_log.save! }.to change { TestLog.count }.by(1)
      expect(test_log.persisted?).to eq(true)

      reloaded_test_log = TestLog.where(date: test_log.date, bucket: test_log.bucket, id: test_log.id).first

      expect(reloaded_test_log.attributes).to eq(test_log.attributes)
    end

    it "executes the hooks" do
      test_log = TestLog.new(timestamp: Time.parse("2016-11-01 12:00:00"), username: "username")
      test_log.save!

      expect(test_log.date).to eq(Date.parse("2016-11-01"))
      expect(test_log.username).to eq("username")
      expect(test_log.bucket).to be_present
      expect(test_log.id).to be_present
    end
  end

  describe "#valid?" do
    it "respects the validation context for create" do
      test_log = TestLogWithContext.new
      test_log.valid?

      expect(test_log.errors[:username]).to include("can't be blank")
    end

    it "respects the validation context for update" do
      test_log = TestLogWithContext.create!(username: "username", timestamp: Time.now)
      test_log.username = nil
      test_log.valid?

      expect(test_log.errors[:username]).not_to include("can't be blank")
      expect(test_log.errors[:query]).to include("can't be blank")
    end
  end

  describe ".create" do
    it "assigns the attributes" do
      test_log = TestLog.create(timestamp: Time.parse("2016-11-01 12:00:00"), username: "username")

      expect(test_log.timestamp).to eq(Time.parse("2016-11-01 12:00:00").utc.round(3))
      expect(test_log.username).to eq("username")
    end

    it "delegates to save" do
      allow_any_instance_of(TestLog).to receive(:save).and_raise("delegated")

      expect { TestLog.create(timestamp: Time.parse("2016-11-01 12:00:00"), username: "username") }.to raise_error("delegated")
    end
  end

  describe ".create!" do
    it "assigns the attributes" do
      test_log = TestLog.create!(timestamp: Time.parse("2016-11-01 12:00:00"), username: "username")

      expect(test_log.timestamp).to eq(Time.parse("2016-11-01 12:00:00").utc.round(3))
      expect(test_log.username).to eq("username")
    end

    it "delegates to save!" do
      allow_any_instance_of(TestLog).to receive(:save!).and_raise("delegated")

      expect { TestLog.create!(timestamp: Time.parse("2016-11-01 12:00:00"), username: "username") }.to raise_error("delegated")
    end
  end

  describe "#update" do
    it "assigns the attributes" do
      test_log = TestLog.create(timestamp: Time.parse("2016-11-01 12:00:00"), username: "username")
      test_log.update(username: "new username", timestamp: Time.parse("2016-11-02 12:00:00"))

      expect(test_log.username).to eq("new username")
      expect(test_log.timestamp).to eq(Time.parse("2016-11-02 12:00:00").utc.round(3))
    end

    it "delegates to save" do
      test_log = TestLog.create(timestamp: Time.parse("2016-11-01 12:00:00"), username: "username")

      allow(test_log).to receive(:save)

      test_log.update(username: "new username", timestamp: Time.parse("2016-11-02 12:00:00"))

      expect(test_log).to have_received(:save)
    end

    it "returns true when the update is successfull" do
      test_log = TestLog.create(timestamp: Time.parse("2016-11-01 12:00:00"), username: "username")

      expect(test_log.update(username: "new username", timestamp: Time.parse("2016-11-02 12:00:00"))).to eq(true)
    end

    it "returns false when the update fails" do
      test_log = TestLog.create(timestamp: Time.parse("2016-11-01 12:00:00"), username: "username")

      expect(test_log.update(timestamp: nil)).to eq(false)
    end
  end

  describe "#update!" do
    it "assigns the attributes" do
      test_log = TestLog.create(timestamp: Time.parse("2016-11-01 12:00:00"), username: "username")
      test_log.update!(username: "new username", timestamp: Time.parse("2016-11-02 12:00:00"))

      expect(test_log.username).to eq("new username")
      expect(test_log.timestamp).to eq(Time.parse("2016-11-02 12:00:00").utc.round(3))
    end

    it "delegates to save!" do
      test_log = TestLog.create(timestamp: Time.parse("2016-11-01 12:00:00"), username: "username")

      allow(test_log).to receive(:save!)

      test_log.update!(username: "new username", timestamp: Time.parse("2016-11-02 12:00:00"))

      expect(test_log).to have_received(:save!)
    end

    it "returns true when the update is successfull" do
      test_log = TestLog.create(timestamp: Time.parse("2016-11-01 12:00:00"), username: "username")

      expect(test_log.update!(username: "new username", timestamp: Time.parse("2016-11-02 12:00:00"))).to eq(true)
    end
  end

  describe "#persisted" do
    it "returns false if the record is not persisted" do
      test_log = TestLog.new(timestamp: Time.parse("2016-11-01 12:00:00"))

      expect(test_log.persisted?).to eq(false)
    end

    it "returns true if the record is persisted" do
      test_log = TestLog.create(timestamp: Time.parse("2016-11-01 12:00:00"))

      expect(test_log.persisted?).to eq(true)
    end
  end

  describe "#new_record?" do
    it "returns true if the record is not yet persisted" do
      test_log = TestLog.new(timestamp: Time.parse("2016-11-01 12:00:00"))

      expect(test_log.new_record?).to eq(true)
    end

    it "returns false if the record is persisted" do
      test_log = TestLog.create(timestamp: Time.parse("2016-11-01 12:00:00"))

      expect(test_log.new_record?).to eq(false)
    end
  end

  describe "#delete" do
    it "deletes the record" do
      test_log1 = TestLog.create(timestamp: Time.parse("2016-11-01 12:00:00"))
      test_log2 = TestLog.create(timestamp: Time.parse("2016-11-01 12:00:00"))

      test_log1.delete

      expect(TestLog.all.to_a).to eq([test_log2])
    end
  end

  describe "#destroy" do
    it "deletes the record and updates the destroyed info" do
      test_log1 = TestLog.create(timestamp: Time.parse("2016-11-01 12:00:00"))
      test_log2 = TestLog.create(timestamp: Time.parse("2016-11-01 12:00:00"))

      test_log1.destroy

      expect(TestLog.all.to_a).to eq([test_log2])
      expect(test_log1.destroyed?).to eq(true)
    end
  end

  describe "#destroyed?" do
    it "returns false when the record was not yet destroyed" do
      test_log = TestLog.new(timestamp: Time.parse("2016-11-01 12:00:00"))

      expect(test_log.destroyed?).to eq(false)
    end

    it "returns true when the record was destroyed" do
      test_log = TestLog.create(timestamp: Time.parse("2016-11-01 12:00:00"))
      test_log.destroy

      expect(test_log.destroyed?).to eq(true)
    end
  end

  describe ".table_name" do
    it "returns the table name" do
      expect(TestLog.table_name).to eq("test_logs")
    end
  end

  describe ".truncate_table" do
    it "deletes all records" do
      TestLog.create!(timestamp: Time.parse("2016-11-01 12:00:00"))
      TestLog.create!(timestamp: Time.parse("2016-11-02 12:00:00"))

      expect { TestLog.truncate_table }.to change { TestLog.count }.by(-2)
    end
  end

  describe ".statement" do
    it "inserts the specified placeholders and quotes the values" do
      statement = TestLog.statement(
        "SELECT * FROM table WHERE date = :date AND id = :id AND message = :message",
        date: Date.parse("2016-12-06"),
        id: 1,
        message: "some'value"
      )

      expect(statement).to eq("SELECT * FROM table WHERE date = '2016-12-06' AND id = 1 AND message = 'some''value'")
    end
  end

  describe ".execute" do
    it "executes the statement and returns the result" do
      records = [
        TestLog.create!(timestamp: Time.parse("2016-11-01 12:00:00")),
        TestLog.create!(timestamp: Time.parse("2016-11-02 12:00:00"))
      ]

      expect(TestLog.execute("SELECT * FROM test_logs", consistency: :all).map { |row| row["id"] }.to_set).to eq(records.map(&:id).to_set)
    end
  end

  describe ".execute_batch" do
    it "executes the statements" do
      records = [
        TestLog.create!(timestamp: Time.parse("2016-11-01 12:00:00")),
        TestLog.create!(timestamp: Time.parse("2016-11-02 12:00:00"))
      ]

      batch = [
        "DELETE FROM test_logs WHERE date = '#{records[0].date.strftime("%F")}' AND bucket = #{records[0].bucket} AND id = #{records[0].id}",
        "DELETE FROM test_logs WHERE date = '#{records[1].date.strftime("%F")}' AND bucket = #{records[1].bucket} AND id = #{records[1].id}"
      ]

      expect { TestLog.execute_batch(batch, consistency: :all) }.to change { TestLog.count }.by(-2)
    end
  end

  describe "#callbacks" do
    let(:temp_log) do
      Class.new(TestLog) do
        def self.table_name
          "test_logs"
        end

        def called_callbacks
          @called_callbacks ||= []
        end

        def reset_called_callbacks
          @called_callbacks = []
        end

        before_validation { called_callbacks << :before_validation }
        after_validation { called_callbacks << :after_validation }
        before_save { called_callbacks << :before_save }
        after_save { called_callbacks << :after_save }
        before_create { called_callbacks << :before_create }
        after_create { called_callbacks << :after_create }
        before_update { called_callbacks << :before_update }
        after_update { called_callbacks << :after_update }
        before_destroy { called_callbacks << :before_destroy }
        after_destroy { called_callbacks << :after_destroy }
      end
    end

    it "executes the correct callbacks in the correct order on create" do
      record = temp_log.create!(timestamp: Time.now)

      expect(record.called_callbacks).to eq([:before_validation, :after_validation, :before_save, :before_create, :after_create, :after_save])
    end

    it "executes the correct callbacks in the correct order on update" do
      record = temp_log.create!(timestamp: Time.now)
      record.reset_called_callbacks
      record.save

      expect(record.called_callbacks).to eq([:before_validation, :after_validation, :before_save, :before_update, :after_update, :after_save])
    end

    it "executes the correct callbacks in the correct order on destroy" do
      record = temp_log.create!(timestamp: Time.now)
      record.reset_called_callbacks
      record.destroy

      expect(record.called_callbacks).to eq([:before_destroy, :after_destroy])
    end
  end

  describe "#validate!" do
    it "raises CassandraRecord::RecordInvalid if validation fails" do
      TestLog.new(timestamp: Time.now).validate!

      expect { TestLog.new.validate! }.to raise_error(CassandraRecord::RecordInvalid)
    end
  end

  describe "dirty attributes" do
    let(:timestamp) { Time.now }

    it "returns true for dirty attributes" do
      test_log = TestLog.new(timestamp: timestamp, username: "username")

      expect(test_log.timestamp_changed?).to eq(true)
      expect(test_log.username_changed?).to eq(true)

      expect(test_log.changes).to eq("timestamp" => [nil, timestamp.utc.round(3)], "username" => [nil, "username"])
    end

    it "resets the dirty attributes after save" do
      test_log = TestLog.new(timestamp: timestamp, username: "username")
      test_log.save!

      expect(test_log.timestamp_changed?).to eq(false)
      expect(test_log.username_changed?).to eq(false)

      expect(test_log.changes).to be_blank
    end
  end

  describe ".key_columns" do
    it "returns the key columns" do
      expect(TestLog.key_columns).to eq(
        date: { type: :date, partition_key: true, clustering_key: false },
        bucket: { type: :int, partition_key: true, clustering_key: false },
        id: { type: :timeuuid, partition_key: false, clustering_key: true }
      )
    end
  end

  describe ".clustering_key_columns" do
    it "returns the clustering key columns" do
      expect(TestLog.clustering_key_columns).to eq(id: { type: :timeuuid, partition_key: false, clustering_key: true })
    end
  end

  describe ".parition_key_columns" do
    it "returns the partition key columns" do
      expect(TestLog.partition_key_columns).to eq(
        date: { type: :date, partition_key: true, clustering_key: false },
        bucket: { type: :int, partition_key: true, clustering_key: false }
      )
    end
  end

  describe "#key_values" do
    it "returns the values of the keys" do
      date = Date.today
      bucket = 1
      id = Cassandra::TimeUuid::Generator.new.at(Time.now)

      expect(TestLog.new(date: date, bucket: bucket, id: id).key_values).to eq([date, bucket, id])
    end
  end

  describe "equality" do
    let(:generator) { Cassandra::TimeUuid::Generator.new }
    let(:id) { generator.at(Time.parse("2017-01-01 12:00:00")) }

    it "returns true if the records have the same key values" do
      record1 = TestLog.new(date: Date.parse("2017-01-01"), bucket: 1, id: id, username: "username1")
      record2 = TestLog.new(date: Date.parse("2017-01-01"), bucket: 1, id: id, username: "username2")

      expect(record1).to eq(record2)
    end

    it "returns false if auto generated keys are not the same" do
      record1 = TestLog.new(date: Date.parse("2017-01-01"), bucket: 1, id: generator.at(Time.parse("2017-01-01 12:00:00")))
      record2 = TestLog.new(date: Date.parse("2017-01-01"), bucket: 1, id: generator.at(Time.parse("2017-01-01 12:00:00")))

      expect(record1).not_to eq(record2)
    end

    it "returns false if key values are not the same" do
      record1 = TestLog.new(date: Date.parse("2017-01-01"), bucket: 1, id: id)
      record2 = TestLog.new(date: Date.parse("2017-01-01"), bucket: 2, id: id)

      expect(record1).not_to eq(record2)
    end
  end
end
