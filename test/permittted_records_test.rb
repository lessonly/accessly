require "test_helper"

describe Accessly do
  it "returns false when actor lacks access to an object" do
    actor = User.create!
    post = Post.create!

    _(Accessly::Query.new(actor).can?(1, Post, post.id)).must_equal false
  end

  it "returns true when the actor has access to an object" do
    actor = User.create!
    post  = Post.create!

    Accessly::PermittedActionOnObject.create!(
      actor: actor,
      action: 1,
      object_type: Post,
      object_id: post.id
    )

    _(Accessly::Query.new(actor).can?(1, Post, post.id)).must_equal true
  end

  it "returns true when the actor has some sort of access to an object" do
    actor = User.create!
    post  = Post.create!
    group = Group.create!

    Accessly::PermittedActionOnObject.create!(
      actor: actor,
      action: 1,
      object_type: Post,
      object_id: post.id
    )

    Accessly::PermittedActionOnObject.create!(
      segment_id: 1,
      actor: group,
      action: 2,
      object_type: Post,
      object_id: post.id
    )

    _(Accessly::Query.new(actor).can?([2,1], Post, post.id)).must_equal true
    _(Accessly::Query.new(actor).on_segment(1).can?([2,1], Post, post.id)).must_equal false

    _(Accessly::Query.new(actor).can?([1,3], Post, post.id)).must_equal true
    _(Accessly::Query.new(actor).on_segment(1).can?([1,3], Post, post.id)).must_equal false

    _(Accessly::Query.new(actor).can?([1], Post, post.id)).must_equal true
    _(Accessly::Query.new(actor).on_segment(1).can?([1], Post, post.id)).must_equal false

    _(Accessly::Query.new(actor).can?(1, Post, post.id)).must_equal true
    _(Accessly::Query.new(actor).on_segment(1).can?(1, Post, post.id)).must_equal false

    _(Accessly::Query.new(actor).can?([3,2], Post, post.id)).must_equal false
    _(Accessly::Query.new(group).can?([3,2], Post, post.id)).must_equal false
    _(Accessly::Query.new(group).on_segment(1).can?([3,2], Post, post.id)).must_equal true
  end

  it "returns true when one of the actor groups has some sort of access to an object" do
    actor1 = User.create!
    actor2 = User.create!
    actor3 = User.create!
    post   = Post.create!
    group1 = Group.create!
    group2 = Group.create!

    Accessly::PermittedActionOnObject.create!(
      actor: actor1,
      action: 1,
      object_type: Post,
      object_id: post.id
    )

    Accessly::PermittedActionOnObject.create!(
      actor: actor3,
      action: 1,
      object_type: Post,
      object_id: post.id
    )

    Accessly::PermittedActionOnObject.create!(
      actor: group1,
      action: 2,
      object_type: Post,
      object_id: post.id
    )

    Accessly::PermittedActionOnObject.create!(
      segment_id: 1,
      actor: group1,
      action: 5,
      object_type: Post,
      object_id: post.id
    )

    _(Accessly::Query.new(User => actor1.id).can?([2,1], Post, post.id)).must_equal true
    _(Accessly::Query.new(User => actor1.id).on_segment(1).can?([2,1], Post, post.id)).must_equal false

    _(Accessly::Query.new(User => actor2.id).can?([2,1], Post, post.id)).must_equal false
    _(Accessly::Query.new(User => actor2.id).on_segment(1).can?([2,1], Post, post.id)).must_equal false

    _(Accessly::Query.new(User => actor2.id, Group => group1.id).can?(2, Post, post.id)).must_equal true
    _(Accessly::Query.new(User => actor2.id, Group => group1.id).on_segment(1).can?(2, Post, post.id)).must_equal false

    _(Accessly::Query.new(User => [actor3.id, actor2.id]).can?([1,3], Post, post.id)).must_equal true
    _(Accessly::Query.new(User => [actor3.id, actor2.id, actor1.id], Group => [group1.id, group2.id]).can?([3,4], Post, post.id)).must_equal false
    _(Accessly::Query.new(group1).on_segment(1).can?(5, Post, post.id)).must_equal true
  end
end
