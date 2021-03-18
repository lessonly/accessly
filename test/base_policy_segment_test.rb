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

    _(UnsegmentedPostPolicy.new(user).view?).must_equal false
    _(UnsegmentedPostPolicy.new(user).can?(:view)).must_equal false
    _(UnsegmentedPostPolicy.new(user).edit?(post)).must_equal false
    _(UnsegmentedPostPolicy.new(user).can?(:edit, post)).must_equal false

    Accessly::PermittedAction.create!(
      segment_id: -1,
      actor: user,
      action: 1,
      object_type: String(Post)
    )

    _(UnsegmentedPostPolicy.new(user).view?).must_equal true
    _(UnsegmentedPostPolicy.new(user).can?(:view)).must_equal true

    Accessly::PermittedActionOnObject.create!(
      segment_id: -1,
      actor: user,
      action: 1,
      object_type: String(Post),
      object_id: post.id
    )

    _(UnsegmentedPostPolicy.new(user).edit?(post)).must_equal true
    _(UnsegmentedPostPolicy.new(user).can?(:edit, post)).must_equal true
  end

  it "uses segment in general action lookup" do
    user = User.create!(group_id: 4)
    Accessly::PermittedAction.create!(
      segment_id: -1,
      actor: user,
      action: 1,
      object_type: String(Post)
    )

    _(SegmentedPostPolicy.new(user).view?).must_equal false
    _(SegmentedPostPolicy.new(user).can?(:view)).must_equal false

    Accessly::PermittedAction.create!(
      segment_id: user.group_id,
      actor: user,
      action: 1,
      object_type: String(Post)
    )

    _(SegmentedPostPolicy.new(user).view?).must_equal true
    _(SegmentedPostPolicy.new(user).can?(:view)).must_equal true

  end

  it "uses segment in action on object lookup" do
    user = User.create!(group_id: 4)
    post = Post.create!

    Accessly::PermittedActionOnObject.create!(
      segment_id: -1,
      actor: user,
      action: 1,
      object_type: String(Post),
      object_id: post.id
    )

    _(SegmentedPostPolicy.new(user).view?(post)).must_equal false
    _(SegmentedPostPolicy.new(user).can?(:view, post)).must_equal false

    Accessly::PermittedActionOnObject.create!(
      segment_id: user.group_id,
      actor: user,
      action: 1,
      object_type: String(Post),
      object_id: post.id
    )

    _(SegmentedPostPolicy.new(user).view?(post)).must_equal true
    _(SegmentedPostPolicy.new(user).can?(:view, post)).must_equal true

  end

  it "uses segment in general action grant and revoke" do
    user = User.create!(group_id: 5)

    SegmentedPostPolicy.new(user).grant!(:view)

    _(Accessly::PermittedAction.where(
      segment_id: 5,
      actor: user,
      object_type: String(Post)
    ).size).must_equal 1

    SegmentedPostPolicy.new(user).revoke!(:view)

    _(Accessly::PermittedAction.where(
      segment_id: 5,
      actor: user,
      object_type: String(Post)
    ).size).must_equal 0
  end

  it "uses segment in action on object grant and revoke" do
    user = User.create!(group_id: 5)
    post = Post.create!

    SegmentedPostPolicy.new(user).grant!(:view, post)

    _(Accessly::PermittedActionOnObject.where(
      segment_id: 5,
      actor: user,
      object_type: String(Post),
      object_id: post.id
    ).size).must_equal 1

    SegmentedPostPolicy.new(user).revoke!(:view, post)

    _(Accessly::PermittedActionOnObject.where(
      segment_id: 5,
      actor: user,
      object_type: String(Post),
      object_id: post.id
    ).size).must_equal 0
  end

  it "uses segment in action list lookup" do
    user = User.create!(group_id: 7)

    post_in_segment1 = Post.create!
    post_in_segment2 = Post.create!
    post_outside_segment = Post.create!

    [post_in_segment1, post_in_segment2].each do |post|
      Accessly::PermittedActionOnObject.create!(
        segment_id: user.group_id,
        actor: user,
        action: 1,
        object_type: String(Post),
        object_id: post.id
      )
    end

    Accessly::PermittedActionOnObject.create!(
      segment_id: -1,
      actor: user,
      action: 1,
      object_type: String(Post),
      object_id: post_outside_segment.id
    )

    _(SegmentedPostPolicy.new(user).view.order(:id)).must_equal [post_in_segment1, post_in_segment2]
    _(SegmentedPostPolicy.new(user).list(:view).order(:id)).must_equal [post_in_segment1, post_in_segment2]
  end
end
