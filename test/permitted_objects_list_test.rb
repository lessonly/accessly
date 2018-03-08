require 'test_helper'

describe AccessControl do

  it 'returns an ActiveRecord::Relation of the object class' do
    return_value = AccessControl.list(User.create!, 1, Post)

    return_value.class.ancestors.must_include ActiveRecord::Relation
    return_value.model.must_equal Post
  end

  it 'returns a list of records the actor has access to with the given action' do
    actor1 = User.create!
    actor2 = User.create!
    post1 = Post.create!
    post2 = Post.create!
    post3 = Post.create!

    [post1, post3].each do |post|
      AccessControl::PermittedActionOnObject.create!(
        id: SecureRandom.uuid,
        actor: actor1,
        action: 1,
        object_type: Post,
        object_id: post.id
      )
    end

    [post2, post3].each do |post|
      AccessControl::PermittedActionOnObject.create!(
        id: SecureRandom.uuid,
        actor: actor2,
        action: 2,
        object_type: Post,
        object_id: post.id
      )
    end

    AccessControl.list(actor1, 1, Post).order(:id).must_equal [post1, post3]
    AccessControl.list(actor1, 2, Post).order(:id).must_equal []
    AccessControl.list(actor1, 3, Post).order(:id).must_equal []

    AccessControl.list(actor2, 1, Post).order(:id).must_equal []
    AccessControl.list(actor2, 2, Post).order(:id).must_equal [post2, post3]
    AccessControl.list(actor2, 3, Post).order(:id).must_equal []
  end

  it 'does not accept an array of actions' do
    -> { AccessControl.list(User.create!, [1, 2, 3], Post) }.must_raise TypeError
  end
end
