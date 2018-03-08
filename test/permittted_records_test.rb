require 'test_helper'

describe AccessControl do
  it 'returns false when actor lacks access to an object' do
    actor = User.create!
    post = Post.create!

    AccessControl.can?(actor, 1, Post, post.id).must_equal false
  end

  it 'retuns true when the actor has access to an object' do
    actor = User.create!
    post  = Post.create!

    AccessControl::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      actor: actor,
      action: 1,
      object_type: Post,
      object_id: post.id
    )

    AccessControl.can?(actor, 1, Post, post.id).must_equal true
  end

  it 'retuns true when the actor has some sort of access to an object' do
    actor = User.create!
    post  = Post.create!

    AccessControl::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      actor: actor,
      action: 1,
      object_type: Post,
      object_id: post.id
    )

    AccessControl.can?(actor, [2,1], Post, post.id).must_equal true
    AccessControl.can?(actor, [1,3], Post, post.id).must_equal true
    AccessControl.can?(actor, [1], Post, post.id).must_equal true
    AccessControl.can?(actor, 1, Post, post.id).must_equal true
    AccessControl.can?(actor, [3,2], Post, post.id).must_equal false
  end
end
