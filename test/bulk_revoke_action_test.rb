require "test_helper"

describe Accessly do
  it "returns nil after a successful revocation" do
    5.times do
      actor = User.create!
      Accessly::PermittedAction.create!(
        actor: actor, action: 1,
        object_type: "Post"
      )
    end

    _(Accessly::Permission::BulkRevoke.new.revoke!(1, Post)).must_be_nil
    _(Accessly::PermittedAction.where(action: 1, actor: User.last(5)).count).must_equal 0
  end
end
