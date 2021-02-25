require "test_helper"

describe Accessly do
  it "caches the result of general permitted action" do
    actor = User.create!
    query = Accessly::Query.new(actor)
    _(query.can?(1, Post)).must_equal false

    Accessly::PermittedAction.create!(
      actor: actor,
      action: 1,
      object_type: Post
    )

    _(query.can?(1, Post)).must_equal false
    _(Accessly::Query.new(actor).can?(1, Post)).must_equal true
  end

  it "caches the result of permitted action on object" do
    actor = User.create!
    post = Post.create!

    permitted_action = Accessly::PermittedActionOnObject.create!(
      actor: actor,
      action: 9,
      object_type: Post,
      object_id: post.id
    )

    query = Accessly::Query.new(actor)
    _(query.can?(9, Post, post.id)).must_equal true

    permitted_action.destroy!

    _(query.can?(9, Post, post.id)).must_equal true
    _(Accessly::Query.new(actor).can?(9, Post, post.id)).must_equal false
  end
end
