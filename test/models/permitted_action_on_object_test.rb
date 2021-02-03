require "test_helper"

describe Accessly::PermittedActionOnObject do
  describe "#before_create" do
    it "creates a record with a UUID if :uuid is supported" do
      actor = User.create!
      post  = Post.create!
      record = Accessly::PermittedActionOnObject.create(
        actor: actor,
        action: 1,
        object_type: Post,
        object_id: post.id
      )

      assert_instance_of(String, record.id)
    end
  end
end
