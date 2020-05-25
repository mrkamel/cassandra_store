require File.expand_path("../spec_helper", __dir__)

RSpec.describe CassandraStore::SchemaMigration do
  describe ".create_table" do
    it "creates the schema migration table" do
      expect { described_class.create(version: Time.now.to_i) }.to raise_error(Cassandra::Errors::InvalidError)

      described_class.create_table

      expect { described_class.create(version: Time.now.to_i) }.not_to raise_error
    end

    it "respects the if_not_exists option" do
      described_class.create_table

      expect { described_class.create_table(if_not_exists: true) }.not_to raise_error
    end
  end
end
