require "test_helper"
require "accessly/policy/base"

describe Accessly::Policy::Base do

  class UserInGroupsPolicy < Accessly::Policy::Base

    actions view: 1
    actions_on_objects view: 1

    def self.namespace
      User.name
    end

    def self.model_scope
      User.all
    end

    def actors
      { User => actor.id, Group => actor.group.id }
    end
  end

  it "uses the actors defined in the class for general permission lookups" do
    group = Group.create!
    user = User.create!(group: group)

    _(UserInGroupsPolicy.new(user).view?).must_equal false
    _(UserInGroupsPolicy.new(user).can?(:view)).must_equal false

    Accessly::PermittedAction.create!(
      id: SecureRandom.uuid,
      segment_id: -1,
      actor: group,
      action: 1,
      object_type: String(User)
    )

    _(UserInGroupsPolicy.new(user).view?).must_equal true
    _(UserInGroupsPolicy.new(user).can?(:view)).must_equal true
  end

  it "uses the actors defined in the class for object permission lookups" do
    group = Group.create!
    user = User.create!(group: group)
    other_user = User.create!

    _(UserInGroupsPolicy.new(user).view?(other_user)).must_equal false
    _(UserInGroupsPolicy.new(user).can?(:view, other_user)).must_equal false

    Accessly::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      segment_id: -1,
      actor: group,
      action: 1,
      object_type: String(User),
      object_id: other_user.id
    )

    _(UserInGroupsPolicy.new(user).view?(other_user)).must_equal true
    _(UserInGroupsPolicy.new(user).can?(:view, other_user)).must_equal true
  end

  it "uses the actors defined in the class for list lookups" do
    group = Group.create!
    user = User.create!(group: group)
    other_user = User.create!

    _(UserInGroupsPolicy.new(user).view?(other_user)).must_equal false
    _(UserInGroupsPolicy.new(user).can?(:view, other_user)).must_equal false

    Accessly::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      segment_id: -1,
      actor: group,
      action: 1,
      object_type: String(User),
      object_id: other_user.id
    )

    _(UserInGroupsPolicy.new(user).view).must_equal [other_user]
    _(UserInGroupsPolicy.new(user).list(:view)).must_equal [other_user]

  end

  it "does not grant the additional actors permissions with #grant" do
    group = Group.create!
    user = User.create!(group: group)

    UserInGroupsPolicy.new(user).grant!(:view)

    _(Accessly::PermittedAction.where(actor: user).exists?).must_equal true
    _(Accessly::PermittedAction.where(actor: group).exists?).must_equal false
  end

  it "does not revoke the additional actors permissions with #revoke" do
    group = Group.create!
    user = User.create!(group: group)

    Accessly::PermittedAction.create!(
      id: SecureRandom.uuid,
      segment_id: -1,
      actor: user,
      action: 1,
      object_type: String(User)
    )

    Accessly::PermittedAction.create!(
      id: SecureRandom.uuid,
      segment_id: -1,
      actor: group,
      action: 1,
      object_type: String(User)
    )

    UserInGroupsPolicy.new(user).revoke!(:view)

    _(Accessly::PermittedAction.where(actor: user).exists?).must_equal false
    _(Accessly::PermittedAction.where(actor: group).exists?).must_equal true
  end
end
