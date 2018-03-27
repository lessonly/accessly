require "test_helper"
require "accessly/policy/base"

describe Accessly::Policy::Base do

  class UnsegmentedPostPolicy < Accessly::Policy::Base
    actions view: 1
    actions_on_objects edit: 1

    def self.namespace
      Post.name
    end

    def self.model_scope
      Post.all
    end
  end

  class SegmentedPostPolicy < Accessly::Policy::Base

    actions view: 1, edit: 2
    actions_on_objects view: 1, edit: 2

    def self.namespace
      Post.name
    end

    def self.model_scope
      Post.all
    end

    def segment_id
      actor.group_id
    end
  end

  it "does not use a segment when no segment id is set" do
    user = User.create!(group_id: 4)
    post = Post.create!

    UnsegmentedPostPolicy.new(user).view?.must_equal false
    UnsegmentedPostPolicy.new(user).view?(post).must_equal false

    Accessly::PermittedAction.create!(
      id: SecureRandom.uuid,
      segment_id: -1,
      actor: user,
      action: 1,
      object_type: String(Post)
    )

    UnsegmentedPostPolicy.new(user).view?.must_equal true

    Accessly::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      segment_id: -1,
      actor: user,
      action: 1,
      object_type: String(Post),
      object_id: post.id
    )

    UnsegmentedPostPolicy.new(user).view?(post).must_equal true
  end

  it "uses segment in general action lookup" do
    user = User.create!(group_id: 4)
    Accessly::PermittedAction.create!(
      id: SecureRandom.uuid,
      segment_id: -1,
      actor: user,
      action: 1,
      object_type: String(Post)
    )

    SegmentedPostPolicy.new(user).view?.must_equal false

    Accessly::PermittedAction.create!(
      id: SecureRandom.uuid,
      segment_id: user.group_id,
      actor: user,
      action: 1,
      object_type: String(Post)
    )

    SegmentedPostPolicy.new(user).view?.must_equal true
  end

  it "uses segment in action on object lookup" do
    user = User.create!(group_id: 4)
    post = Post.create!

    Accessly::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      segment_id: -1,
      actor: user,
      action: 1,
      object_type: String(Post),
      object_id: post.id
    )

    SegmentedPostPolicy.new(user).view?(post).must_equal false

    Accessly::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      segment_id: user.group_id,
      actor: user,
      action: 1,
      object_type: String(Post),
      object_id: post.id
    )

    SegmentedPostPolicy.new(user).view?(post).must_equal true
  end

  it "uses segment in general action grant and revoke" do
    user = User.create!(group_id: 5)

    SegmentedPostPolicy.new(user).grant(:view)

    Accessly::PermittedAction.where(
      segment_id: 5,
      actor: user,
      object_type: String(Post)
    ).size.must_equal 1

    SegmentedPostPolicy.new(user).revoke(:view)

    Accessly::PermittedAction.where(
      segment_id: 5,
      actor: user,
      object_type: String(Post)
    ).size.must_equal 0
  end

  it "uses segment in action on object grant and revoke" do
    user = User.create!(group_id: 5)
    post = Post.create!

    SegmentedPostPolicy.new(user).grant(:view, post)

    Accessly::PermittedActionOnObject.where(
      segment_id: 5,
      actor: user,
      object_type: String(Post),
      object_id: post.id
    ).size.must_equal 1

    SegmentedPostPolicy.new(user).revoke(:view, post)

    Accessly::PermittedActionOnObject.where(
      segment_id: 5,
      actor: user,
      object_type: String(Post),
      object_id: post.id
    ).size.must_equal 0
  end

  it "uses segment in action list lookup" do
    user = User.create!(group_id: 7)

    post_in_segment1 = Post.create!
    post_in_segment2 = Post.create!
    post_outside_segment = Post.create!

    [post_in_segment1, post_in_segment2].each do |post|
      Accessly::PermittedActionOnObject.create!(
        id: SecureRandom.uuid,
        segment_id: user.group_id,
        actor: user,
        action: 1,
        object_type: String(Post),
        object_id: post.id
      )
    end

    Accessly::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      segment_id: -1,
      actor: user,
      action: 1,
      object_type: String(Post),
      object_id: post_outside_segment.id
    )

    SegmentedPostPolicy.new(user).view.order(:id).must_equal [post_in_segment1, post_in_segment2]
  end
end
