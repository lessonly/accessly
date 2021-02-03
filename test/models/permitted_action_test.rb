require "test_helper"

describe Accessly::PermittedActionOnObject do
  describe "#before_create" do
    it "creates a record with a UUID if :uuid is supported" do
      actor = User.create!
      record = Accessly::PermittedAction.create(
        actor: actor,
        action: 1,
        object_type: Post,
      )

      assert_instance_of(String, record.id)
    end
  end
end
