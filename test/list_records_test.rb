require "test_helper"

describe Accessly do

  it "returns a list of objects" do
    actor1 = User.create!
    actor2 = User.create!
    post1  = Post.create!
    post2  = Post.create!
    post3  = Post.create!
    group1 = Group.create!
    group2 = Group.create!

    Accessly::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      actor: actor1,
      action: 1,
      object_type: Post,
      object_id: post1.id
    )

    Accessly::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      actor: actor1,
      action: 1,
      object_type: Post,
      object_id: post2.id
    )

    Accessly::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      actor: group1,
      action: 2,
      object_type: Post,
      object_id: post3.id
    )

    Accessly::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      actor: group2,
      action: 1,
      object_type: Post,
      object_id: post3.id
    )

    _(Accessly::Query.new(actor2).list(1, Post)).must_equal []

    actor1_list = Accessly::Query.new(actor1).list(1, Post)
    _(actor1_list.is_a? ActiveRecord::Relation).must_equal true
    _(Post.where(id: actor1_list).sort.to_a.map { |post| post.id  }).must_equal [ post1.id, post2.id ]

    _(Accessly::Query.new(group1).list(1, Post)).must_equal []
    group1_list = Accessly::Query.new(group1).list(2, Post)
    _(group1_list.is_a? ActiveRecord::Relation).must_equal true
    _(Post.where(id: group1_list).sort.to_a.map { |post| post.id  }).must_equal [ post3.id ]

    combined_list = Accessly::Query.new(User => actor1.id, Group => group2.id).list(1, Post)
    _(combined_list.is_a? ActiveRecord::Relation).must_equal true
    _(Post.where(id: combined_list).sort.to_a.map { |post| post.id  }).must_equal [ post1.id, post2.id, post3.id ]

  end

  it "returns a list of objects on a segment" do
    actor1 = User.create!
    actor2 = User.create!
    post1  = Post.create!
    post2  = Post.create!
    post3  = Post.create!
    group1 = Group.create!
    group2 = Group.create!

    Accessly::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      segment_id: 1,
      actor: actor1,
      action: 1,
      object_type: Post,
      object_id: post1.id
    )

    Accessly::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      segment_id: 1,
      actor: actor1,
      action: 1,
      object_type: Post,
      object_id: post2.id
    )

    Accessly::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      segment_id: 1,
      actor: group1,
      action: 2,
      object_type: Post,
      object_id: post3.id
    )

    Accessly::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      segment_id: 1,
      actor: group2,
      action: 1,
      object_type: Post,
      object_id: post3.id
    )

    _(Accessly::Query.new(actor2).on_segment(1).list(1, Post)).must_equal []

    actor1_list = Accessly::Query.new(actor1).on_segment(1).list(1, Post)
    _(actor1_list.is_a? ActiveRecord::Relation).must_equal true
    _(Post.where(id: actor1_list).sort.to_a.map { |post| post.id  }).must_equal [ post1.id, post2.id ]

    _(Accessly::Query.new(group1).on_segment(1).list(1, Post)).must_equal []
    group1_list = Accessly::Query.new(group1).on_segment(1).list(2, Post)
    _(group1_list.is_a? ActiveRecord::Relation).must_equal true
    _(Post.where(id: group1_list).sort.to_a.map { |post| post.id  }).must_equal [ post3.id ]

    combined_list = Accessly::Query.new(User => actor1.id, Group => group2.id).on_segment(1).list(1, Post)
    _(combined_list.is_a? ActiveRecord::Relation).must_equal true
    _(Post.where(id: combined_list).sort.to_a.map { |post| post.id  }).must_equal [ post1.id, post2.id, post3.id ]

  end
end
