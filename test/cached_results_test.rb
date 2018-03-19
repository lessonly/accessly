require "test_helper"

describe AccessControl do
  it "caches the result of general permitted action" do
    actor = User.create!
    query = AccessControl::Query.new(actor)
    query.can?(1, Post).must_equal false

    AccessControl::PermittedAction.create!(
      id: SecureRandom.uuid,
      actor: actor,
      action: 1,
      object_type: Post
    )

    query.can?(1, Post).must_equal false
    AccessControl::Query.new(actor).can?(1, Post).must_equal true
  end

  it "caches the result of permitted action on object" do
    actor = User.create!
    post = Post.create!

    permitted_action = AccessControl::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      actor: actor,
      action: 9,
      object_type: Post,
      object_id: post.id
    )

    query = AccessControl::Query.new(actor)
    query.can?(9, Post, post.id).must_equal true

    permitted_action.destroy!

    query.can?(9, Post, post.id).must_equal true
    AccessControl::Query.new(actor).can?(9, Post, post.id).must_equal false
  end
end
