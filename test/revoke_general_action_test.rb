require "test_helper"

describe Accessly do

  it "returns nil after a successful revoke" do
    actor = User.create!
    Accessly::PermittedAction.create!(id: SecureRandom.uuid, actor: actor, action: 1, object_type: "Post")
    Accessly::PermittedAction.where(actor: actor).count.must_equal 1

    Accessly::Permission::Revoke.new(actor).revoke!(1, Post).must_be_nil
    Accessly::PermittedAction.where(actor: actor).count.must_equal 0
  end

  it "returns nil after a successful revoke on a segment" do
    actor = User.create!
    Accessly::PermittedAction.create!(id: SecureRandom.uuid, segment_id: 1, actor: actor, action: 1, object_type: "Post")
    Accessly::PermittedAction.where(actor: actor, segment_id: 1).count.must_equal 1

    Accessly::Permission::Revoke.new(actor).on_segment(1).revoke!(1, Post).must_be_nil
    Accessly::PermittedAction.where(actor: actor, segment_id: 1).count.must_equal 0
  end

  it "raises an error when attempting to revoke on an actor that is not an ActiveRecord::Base object" do
    actor = User.create!

    proc { Accessly::Permission::Revoke.new(User => actor.id).revoke!(1, Post) }.must_raise Accessly::RevokeError
  end
end
