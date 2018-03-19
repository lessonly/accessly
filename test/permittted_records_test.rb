require "test_helper"

describe AccessControl do
  it "returns false when actor lacks access to an object" do
    actor = User.create!
    post = Post.create!

    AccessControl::Query.new(actor).can?(1, Post, post.id).must_equal false
  end

  it "retuns true when the actor has access to an object" do
    actor = User.create!
    post  = Post.create!

    AccessControl::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      actor: actor,
      action: 1,
      object_type: Post,
      object_id: post.id
    )

    AccessControl::Query.new(actor).can?(1, Post, post.id).must_equal true
  end

  it "retuns true when the actor has some sort of access to an object" do
    actor = User.create!
    post  = Post.create!

    AccessControl::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      actor: actor,
      action: 1,
      object_type: Post,
      object_id: post.id
    )

    AccessControl::Query.new(actor).can?([2,1], Post, post.id).must_equal true
    AccessControl::Query.new(actor).can?([1,3], Post, post.id).must_equal true
    AccessControl::Query.new(actor).can?([1], Post, post.id).must_equal true
    AccessControl::Query.new(actor).can?(1, Post, post.id).must_equal true
    AccessControl::Query.new(actor).can?([3,2], Post, post.id).must_equal false
  end

  it "returns true when one of the actor groups has some sort of access to an object" do
    actor1 = User.create!
    actor2 = User.create!
    actor3 = User.create!
    post   = Post.create!
    group1 = Group.create!
    group2 = Group.create!

    AccessControl::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      actor: actor1,
      action: 1,
      object_type: Post,
      object_id: post.id
    )

    AccessControl::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      actor: actor3,
      action: 1,
      object_type: Post,
      object_id: post.id
    )

    AccessControl::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      actor: group1,
      action: 2,
      object_type: Post,
      object_id: post.id
    )

    # TODO: Looks like we need to either
    # - support sqlite in WhereTuple
    # - or support only postgresql (and update test_helper to reflect that)
    AccessControl::Query.new(User => actor1.id).can?([2,1], Post, post.id).must_equal true
    AccessControl::Query.new(User => actor2.id).can?([2,1], Post, post.id).must_equal false
    AccessControl::Query.new(User => [actor3.id, actor2.id]).can?([1,3], Post, post.id).must_equal true
    AccessControl::Query.new(User => actor2.id, Group => group1.id).can?(2, Post, post.id).must_equal true
    AccessControl::Query.new(User => [actor3.id, actor2.id, actor1.id], Group => [group1.id, group2.id]).can?([3,4], Post, post.id).must_equal false
  end
end
