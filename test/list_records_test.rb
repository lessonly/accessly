require "test_helper"

describe AccessControl do

  it "raises a ListError if object_type is not of ActiveRecord::Base" do
    actor1 = User.create!
    assert_raises(AccessControl::ListError) do
      AccessControl::Query.new(actor1).list(1, {})
    end
  end

  it "returns a list of objects" do
    actor1 = User.create!
    actor2 = User.create!
    post1  = Post.create!
    post2  = Post.create!
    post3  = Post.create!
    group1 = Group.create!
    group2 = Group.create!

    AccessControl::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      actor: actor1,
      action: 1,
      object_type: Post,
      object_id: post1.id
    )

    AccessControl::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      actor: actor1,
      action: 1,
      object_type: Post,
      object_id: post2.id
    )

    AccessControl::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      actor: group1,
      action: 2,
      object_type: Post,
      object_id: post3.id
    )

    AccessControl::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      actor: group2,
      action: 1,
      object_type: Post,
      object_id: post3.id
    )

    AccessControl::Query.new(actor2).list(1, Post).must_equal []

    actor1_list = AccessControl::Query.new(actor1).list(1, Post)
    (actor1_list.is_a? ActiveRecord::Relation).must_equal true
    (actor1_list.to_a.map { |post| post.id  }).must_equal [ post1.id, post2.id ]

    AccessControl::Query.new(group1).list(1, Post).must_equal []
    group1_list = AccessControl::Query.new(group1).list(2, Post)
    (group1_list.is_a? ActiveRecord::Relation).must_equal true
    (group1_list.to_a.map { |post| post.id  }).must_equal [ post3.id ]

    combined_list = AccessControl::Query.new(User => actor1.id, Group => group2.id).list(1, Post)
    (combined_list.is_a? ActiveRecord::Relation).must_equal true
    (combined_list.to_a.map { |post| post.id  }).must_equal [ post1.id, post2.id, post3.id ]

  end

  it "returns a list of objects on a segment" do
    actor1 = User.create!
    actor2 = User.create!
    post1  = Post.create!
    post2  = Post.create!
    post3  = Post.create!
    group1 = Group.create!
    group2 = Group.create!

    AccessControl::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      segment_id: 1,
      actor: actor1,
      action: 1,
      object_type: Post,
      object_id: post1.id
    )

    AccessControl::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      segment_id: 1,
      actor: actor1,
      action: 1,
      object_type: Post,
      object_id: post2.id
    )

    AccessControl::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      segment_id: 1,
      actor: group1,
      action: 2,
      object_type: Post,
      object_id: post3.id
    )

    AccessControl::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      segment_id: 1,
      actor: group2,
      action: 1,
      object_type: Post,
      object_id: post3.id
    )

    AccessControl::Query.new(actor2).on_segment(1).list(1, Post).must_equal []

    actor1_list = AccessControl::Query.new(actor1).on_segment(1).list(1, Post)
    (actor1_list.is_a? ActiveRecord::Relation).must_equal true
    (actor1_list.to_a.map { |post| post.id  }).must_equal [ post1.id, post2.id ]

    AccessControl::Query.new(group1).on_segment(1).list(1, Post).must_equal []
    group1_list = AccessControl::Query.new(group1).on_segment(1).list(2, Post)
    (group1_list.is_a? ActiveRecord::Relation).must_equal true
    (group1_list.to_a.map { |post| post.id  }).must_equal [ post3.id ]

    combined_list = AccessControl::Query.new(User => actor1.id, Group => group2.id).on_segment(1).list(1, Post)
    (combined_list.is_a? ActiveRecord::Relation).must_equal true
    (combined_list.to_a.map { |post| post.id  }).must_equal [ post1.id, post2.id, post3.id ]

  end
end
