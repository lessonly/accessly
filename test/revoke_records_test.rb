require "test_helper"

describe Accessly do

  it "returns nil after a successful revoke" do
    actor = User.create!
    post = Post.create!

    Accessly::PermittedActionOnObject.create!(id: SecureRandom.uuid, actor: actor, action: 1, namespace: Post, namespace_id: post.id)
    Accessly::PermittedActionOnObject.where(actor: actor).count.must_equal 1

    Accessly::Permission::Revoke.new(actor).revoke!(1, Post, post.id).must_be_nil
    Accessly::PermittedActionOnObject.where(actor: actor).count.must_equal 0
  end

  it "returns nil after a successful revoke on a segment" do
    actor = User.create!
    post = Post.create!

    Accessly::PermittedActionOnObject.create!(id: SecureRandom.uuid, segment_id: 1, actor: actor, action: 1, namespace: Post, namespace_id: post.id)
    Accessly::PermittedActionOnObject.where(actor: actor, segment_id: 1).count.must_equal 1

    Accessly::Permission::Revoke.new(actor).on_segment(1).revoke!(1, Post, post.id).must_be_nil
    Accessly::PermittedActionOnObject.where(actor: actor, segment_id: 1).count.must_equal 0
  end

  it "raises an error when attempting to revoke on an actor that is not an ActiveRecord::Base object" do
    actor = User.create!

    proc { Accessly::Permission::Revoke.new(User => actor.id).revoke!(1, Post, 1) }.must_raise Accessly::RevokeError
  end
end
