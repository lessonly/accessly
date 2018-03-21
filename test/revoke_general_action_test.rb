require "test_helper"

describe AccessControl do

  it "returns nil after a successful revoke" do
    actor = User.create!
    AccessControl::PermittedAction.create!(id: SecureRandom.uuid, actor: actor, action: 1, object_type: "Post")
    AccessControl::PermittedAction.where(actor: actor).count.must_equal 1

    assert_nil(AccessControl::Permission::Revoke.new(actor).revoke!(1, Post))
    AccessControl::PermittedAction.where(actor: actor).count.must_equal 0
  end

  it "returns nil after a successful revoke on a segment" do
    actor = User.create!
    AccessControl::PermittedAction.create!(id: SecureRandom.uuid, segment_id: 1, actor: actor, action: 1, object_type: "Post")
    AccessControl::PermittedAction.where(actor: actor, segment_id: 1).count.must_equal 1

    assert_nil(AccessControl::Permission::Revoke.new(actor).on_segment(1).revoke!(1, Post))
    AccessControl::PermittedAction.where(actor: actor, segment_id: 1).count.must_equal 0
  end

  it "raises an error when attempting to revoke on an actor that is not an ActiveRecord::Base object" do
    actor = User.create!

    assert_raises(AccessControl::RevokeError) do
      AccessControl::Permission::Revoke.new(User => actor.id).revoke!(1, Post)
    end
  end
end
