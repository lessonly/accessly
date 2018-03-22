require "test_helper"

describe Accessly do

  it "returns nil after a successful grant" do
    actor = User.create!
    post = Post.create!

    Accessly::Permission::Grant.new(actor).grant!(1, Post, post.id).must_be_nil
  end

  it "returns nil after a successful grant on a segment" do
    actor = User.create!
    post = Post.create!

    Accessly::Permission::Grant.new(actor).on_segment(1).grant!(1, Post, post.id).must_be_nil
  end

  it "returns nil after a duplicate grant with one record in the database" do
    actor = User.create!
    post = Post.create!

    Accessly::Permission::Grant.new(actor).grant!(1, Post, post.id).must_be_nil
    Accessly::Permission::Grant.new(actor).grant!(1, Post, post.id).must_be_nil
    Accessly::PermittedActionOnObject.where(actor: actor).count.must_equal 1
  end

  it "returns nil after a duplicate grant with one record in the database on a segment" do
    actor = User.create!
    post = Post.create!

    Accessly::Permission::Grant.new(actor).on_segment(1).grant!(1, Post, post.id).must_be_nil
    Accessly::Permission::Grant.new(actor).on_segment(1).grant!(1, Post, post.id).must_be_nil
    Accessly::PermittedActionOnObject.where(actor: actor, segment_id: 1).count.must_equal 1
  end

  it "raises an error when attempting to grant" do
    actor = User.create!
    post = Post.create!

    proc { Accessly::Permission::Grant.new(actor).grant!(nil, Post, post.id) }.must_raise Accessly::GrantError
  end

  it "raises an error when attempting to grant a permission on an actor that is not an ActiveRecord::Base object" do
    actor = User.create!
    post = Post.create!

    proc { Accessly::Permission::Grant.new(User => actor.id).grant!(1, Post, post.id) }.must_raise Accessly::GrantError
  end
end
