require File.expand_path("../spec_helper", __dir__)

RSpec.describe CassandraRecord::Migration do
  let(:path) { File.expand_path("../fixtures", __dir__) }

  describe ".up" do
    let(:version) { "1589957812" }

    before { CassandraRecord::SchemaMigration.create_table(if_not_exists: true) }

    it "calls the up migration" do
      migration = double(up: true)

      allow(described_class.migration_class(path, version)).to receive(:new).and_return(migration)

      described_class.up(path, version)

      expect(migration).to have_received(:up)
    end
  end

  describe ".down" do
    let(:version) { "1589957812" }

    before { CassandraRecord::SchemaMigration.create_table(if_not_exists: true) }

    it "calls the down migration" do
      migration = double(down: true)

      allow(described_class.migration_class(path, version)).to receive(:new).and_return(migration)

      described_class.down(path, version)

      expect(migration).to have_received(:down)
    end
  end

  describe ".execute" do
    it "delegates to CassandraRecord::Base.execute" do
      allow(CassandraRecord::Base).to receive(:execute)

      described_class.new.execute("args")

      expect(CassandraRecord::Base).to have_received(:execute).with("args")
    end
  end

  describe ".migrate" do
    before { CassandraRecord::SchemaMigration.create_table(if_not_exists: true) }

    it "runs all pending migrations" do
      migration1 = double(up: true)
      migration2 = double(up: true)

      allow(described_class.migration_class(path, "1589957812")).to receive(:new).and_return(migration1)
      allow(described_class.migration_class(path, "1589957813")).to receive(:new).and_return(migration2)

      described_class.migrate(path)

      expect(migration1).to have_received(:up)
      expect(migration2).to have_received(:up)
    end

    it "does not run already executed migrations" do
      described_class.up(path, "1589957812")

      migration1 = double(up: true)
      migration2 = double(up: true)

      allow(described_class.migration_class(path, "1589957812")).to receive(:new).and_return(migration1)
      allow(described_class.migration_class(path, "1589957813")).to receive(:new).and_return(migration2)

      described_class.migrate(path)

      expect(migration1).not_to have_received(:up)
      expect(migration2).to have_received(:up)
    end
  end
end
