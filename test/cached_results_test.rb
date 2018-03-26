require "test_helper"

describe Accessly do
  it "caches the result of general permitted action" do
    actor = User.create!
    query = Accessly::Query.new(actor)
    query.can?(1, Post).must_equal false

    Accessly::PermittedAction.create!(
      id: SecureRandom.uuid,
      actor: actor,
      action: 1,
      namespace: Post
    )

    query.can?(1, Post).must_equal false
    Accessly::Query.new(actor).can?(1, Post).must_equal true
  end

  it "caches the result of permitted action on object" do
    actor = User.create!
    post = Post.create!

    permitted_action = Accessly::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      actor: actor,
      action: 9,
      namespace: Post,
      namespace_id: post.id
    )

    query = Accessly::Query.new(actor)
    query.can?(9, Post, post.id).must_equal true

    permitted_action.destroy!

    query.can?(9, Post, post.id).must_equal true
    Accessly::Query.new(actor).can?(9, Post, post.id).must_equal false
  end
end
