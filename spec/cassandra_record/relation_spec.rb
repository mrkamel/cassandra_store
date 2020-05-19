require File.expand_path("../spec_helper", __dir__)

RSpec.describe CassandraRecord::Relation do
  describe "#all" do
    it "returns all records" do
      post1 = Post.create!(user: "user", domain: "domain", message: "message1")
      post2 = Post.create!(user: "user", domain: "domain", message: "message2")

      expect(Post.all.to_a.to_set).to eq([post1, post2].to_set)
    end
  end

  describe "#update_all" do
    it "allows to update records via a cql string" do
      post1 = Post.create!(user: "user1", domain: "domain1", message: "message1")
      post2 = Post.create!(user: "user2", domain: "domain2", message: "message2")

      Post.where(user: "user1", domain: "domain1", id: post1.id).update_all("message = 'new message'")

      post1 = Post.where(user: "user1", domain: "domain1", id: post1.id).first
      post2 = Post.where(user: "user2", domain: "domain2", id: post2.id).first

      expect(post1.message).to eq("new message")
      expect(post2.message).to eq("message2")
    end

    it "allows to update records via a hash" do
      post1 = Post.create!(user: "user1", domain: "domain1", message: "message1")
      post2 = Post.create!(user: "user2", domain: "domain2", message: "message2")

      Post.where(user: "user1", domain: "domain1", id: post1.id).update_all(message: "new message")

      post1 = Post.where(user: "user1", domain: "domain1", id: post1.id).first
      post2 = Post.where(user: "user2", domain: "domain2", id: post2.id).first

      expect(post1.message).to eq("new message")
      expect(post2.message).to eq("message2")
    end
  end

  describe "#where" do
    it "is chainable" do
      post1 = Post.create!(user: "user", domain: "domain1", message: "message1")
      post2 = Post.create!(user: "user", domain: "domain1", message: "message2")
      post3 = Post.create!(user: "user", domain: "domain2", message: "message1")

      posts = Post.where(user: "user").where(domain: "domain1").to_a

      expect(posts.to_a.to_set).to eq([post1, post2].to_set)
    end

    it "allows to pass multiple hash arguments" do
      post1 = Post.create!(user: "user", domain: "domain1", message: "message1")
      post2 = Post.create!(user: "user", domain: "domain1", message: "message2")
      post3 = Post.create!(user: "user", domain: "domain2", message: "message1")

      posts = Post.where(user: "user", domain: "domain1").to_a

      expect(posts.to_a.to_set).to eq([post1, post2].to_set)
    end

    it "allows to pass an array as constraint" do
      post1 = Post.create!(user: "user", domain: "domain1")
      post2 = Post.create!(user: "user", domain: "domain2")
      post3 = Post.create!(user: "user", domain: "domain3")

      posts = Post.where(user: "user").where(domain: ["domain1", "domain2"]).to_a

      expect(posts.to_a.to_set).to eq([post1, post2].to_set)
    end

    it "allows to pass a range as constraint" do
      post1 = Post.create!(user: "user", domain: "domain1")
      post2 = Post.create!(user: "user", domain: "domain2")
      post3 = Post.create!(user: "user", domain: "domain3")

      expect(Post.where(user: "user").where(domain: "domain1".."domain2").to_a.to_set).to eq([post1, post2].to_set)
    end

    it "allows to pass an arbitrary cql string" do
      post1 = Post.create!(user: "user", domain: "domain1", message: "message1")
      post2 = Post.create!(user: "user", domain: "domain1", message: "message2")
      post3 = Post.create!(user: "user", domain: "domain2", message: "message1")

      expect(Post.where_cql("user = 'user'").where_cql("domain = :domain", domain: "domain1").to_a.to_set).to eq([post1, post2].to_set)
    end
  end

  describe "#order" do
    it "sorts the records by the specified criteria" do
      post1 = Post.create!(user: "user", domain: "domain", timestamp: Time.now)
      post2 = Post.create!(user: "user", domain: "domain", timestamp: Time.now + 1.day)
      post3 = Post.create!(user: "user", domain: "domain", timestamp: Time.now + 2.days)

      expect(Post.where(user: "user", domain: "domain").order(id: :asc).to_a).to eq([post1, post2, post3])
      expect(Post.where(user: "user", domain: "domain").order(id: :desc).to_a).to eq([post3, post2, post1])
    end
  end

  describe "#limit" do
    it "limits the records returned" do
      Post.create!(user: "user", domain: "domain", timestamp: Time.now)
      Post.create!(user: "user", domain: "domain", timestamp: Time.now)
      Post.create!(user: "user", domain: "domain", timestamp: Time.now)
      Post.create!(user: "user", domain: "domain", timestamp: Time.now)

      expect(Post.limit(2).find_each.count).to eq(2)
      expect(Post.where(user: "user", domain: "domain").limit(2).find_each.count).to eq(2)

      expect(Post.limit(3).find_each.count).to eq(3)
      expect(Post.where(user: "user", domain: "domain").limit(3).find_each.count).to eq(3)
    end
  end

  describe "#first" do
    it "returns the first record" do
      post1 = Post.create!(user: "user", domain: "domain", timestamp: Time.now - 1.day)
      post2 = Post.create!(user: "user", domain: "domain", timestamp: Time.now + 1.day)

      expect(Post.where(user: "user", domain: "domain").order(id: :asc).first).to eq(post1)
      expect(Post.where(user: "user", domain: "domain").order(id: :desc).first).to eq(post2)
    end
  end

  describe "#distinct" do
    it "returns distinct values for the specified columns" do
      Post.create!(user: "user1", domain: "domain1", timestamp: Time.now)
      Post.create!(user: "user1", domain: "domain1", timestamp: Time.now)
      Post.create!(user: "user1", domain: "domain2", timestamp: Time.now)
      Post.create!(user: "user1", domain: "domain2", timestamp: Time.now)
      Post.create!(user: "user2", domain: "domain1", timestamp: Time.now)
      Post.create!(user: "user2", domain: "domain1", timestamp: Time.now)

      expect(Post.select(:user, :domain).distinct.find_each.to_a).to eq(
        [
          { "user" => "user1", "domain" => "domain1" },
          { "user" => "user1", "domain" => "domain2" },
          { "user" => "user2", "domain" => "domain1" }
        ]
      )
    end
  end

  describe "#select" do
    it "returns the specified columns only" do
      Post.create!(user: "user1", domain: "domain1", timestamp: Time.now)
      Post.create!(user: "user2", domain: "domain2", timestamp: Time.now)

      expect(Post.select(:user, :domain).find_each.to_a).to eq(
        [
          { "user" => "user1", "domain" => "domain1" },
          { "user" => "user2", "domain" => "domain2" }
        ]
      )
    end
  end

  describe "#find_each" do
    it "returns all records" do
      Post.create!(user: "user", domain: "domain", message: "message1", timestamp: Time.now)
      Post.create!(user: "user", domain: "domain", message: "message2", timestamp: Time.now + 1.day)
      Post.create!(user: "user", domain: "domain", message: "message3", timestamp: Time.now + 2.days)

      expect(Post.find_each(batch_size: 2).map(&:message)).to eq(["message1", "message2", "message3"])
    end
  end

  describe "#find_in_batches" do
    it "returns all records in batches" do
      Post.create!(user: "user", domain: "domain", message: "message1", timestamp: Time.now)
      Post.create!(user: "user", domain: "domain", message: "message2", timestamp: Time.now + 1.day)
      Post.create!(user: "user", domain: "domain", message: "message3", timestamp: Time.now + 2.days)

      expect(Post.find_in_batches(batch_size: 2).map { |batch| batch.map(&:message) }).to eq([["message1", "message2"], ["message3"]])
    end
  end

  describe "#count" do
    it "returns the number of records" do
      Post.create!(user: "user1", domain: "domain", timestamp: Time.now)
      Post.create!(user: "user1", domain: "domain", timestamp: Time.now)
      Post.create!(user: "user2", domain: "domain", timestamp: Time.now)

      expect(Post.count).to eq(3)
      expect(Post.where(user: "user1", domain: "domain").count).to eq(2)
    end
  end

  describe "#delete_all" do
    it "deletes the specified records" do
      post1 = Post.create!(user: "user", domain: "domain1", timestamp: Time.now)
      post2 = Post.create!(user: "user", domain: "domain1", timestamp: Time.now)
      post3 = Post.create!(user: "user", domain: "domain2", timestamp: Time.now)

      Post.where(user: "user", domain: "domain1").delete_all

      expect(Post.all.to_a).to eq([post3])
    end
  end

  describe "#delete_in_batches" do
    it "deletes the records in batches" do
      post1 = Post.create!(user: "user", domain: "domain1", timestamp: Time.now)
      post2 = Post.create!(user: "user", domain: "domain1", timestamp: Time.now)
      post3 = Post.create!(user: "user", domain: "domain2", timestamp: Time.now)

      Post.where(user: "user", domain: "domain1").delete_in_batches

      expect(Post.all.to_a).to eq([post3])
    end
  end

  describe "#to_a" do
    it "converts the relation to an array" do
      Post.create!(user: "user", domain: "domain1", message: "message1", timestamp: Time.now)
      Post.create!(user: "user", domain: "domain1", message: "message2", timestamp: Time.now)
      Post.create!(user: "user", domain: "domain2", message: "message3", timestamp: Time.now)

      expect(Post.where(user: "user", domain: "domain1").to_a.map(&:message).to_set).to eq(["message1", "message2"].to_set)
    end
  end
end
