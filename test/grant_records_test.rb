require 'test_helper'

describe AccessControl do

  it 'returns nil after a successful grant' do
    actor = User.create!
    post = Post.create!

    assert_nil(AccessControl::Query.new(actor).grant(1, Post, post.id))
  end

  it 'retuns raises an error the actor has access' do
    actor = User.create!
    post = Post.create!

    assert_nil(AccessControl::Query.new(actor).grant(1, Post, post.id))
    assert_raises(AccessControl::CouldNotGrantError) do
      AccessControl::Query.new(actor).grant(1, Post, post.id)
    end
  end
end
