require "test_helper"
require "accessly/policy/base"

describe Accessly::Policy::Base do
############
# NOTE TO SELF
# I am implementing an API like this:
# UserPolicy.new(user).view?
# UserPolicy.new(user).view?(other_user)
# UserPolicy.new(user).view_list
#
# But I think we decided we wanted the more verbose option:
# UserPolicy.new(user).can?(:view)
# UserPolicy.new(user).can?(:view, other_user)
# UserPolicy.new(user).list(:view)
#
# And that would make sense specifically for the list option, which should be able to OR multiple actions together:
# UserPolicy.new(user).list(:view, :edit, :assign)
#
# But I'm not totally sure yet. Keep this in mind before you get too far.
############

  class UserPolicy < Accessly::Policy::Base

    actions(
      view: 1,
      edit_basic_info: 2,
      change_role: 3,
      destroy: 4
    )

    actions_on_objects(
      view: 1,
      edit_basic_info: 2,
      change_role: 3,
      email: 4
    )

    def self.object_type
      User
    end

    # def segment_id(actor, object)
    #   actor.organization_id
    # end

    # def super_admin?(actor)
    #   actor.admin?
    # end

    # def view?
    #   # Can view users, generally
    # end

    # def edit_basic_info?
    #   # Can edit users' basic information, generally
    # end

    # def change_role?
    #   # Can change users' roles, generally
    # end

    # def destroy?
    #   # Can destroy users, generally
    # end

    # def view_list
    #   # List of users can view
    # end

    # def edit_basic_info_list
    #   # List of users can edit basic info
    # end

    # def change_role_list
    #   # List of users can change role
    # end

    # def email_list
    #   # List of users can send an email to
    # end

    # def view?(object)
    #   # Can view this user?
    # end

    # def edit_basic_info?(object)
    #   # Can edit this user?
    # end

    # def change_role?(object)
    #   # Can change this user's role?
    # end

    # def email?
    #   # Can email this user?
    # end
  end

  class PolicyWithoutObjectType < Accessly::Policy::Base
    actions view: 1
  end

  it "defines action lookup methods" do
    user = User.create!
    other_user = User.create!

    UserPolicy.new(user).view?
    UserPolicy.new(user).edit_basic_info?
    UserPolicy.new(user).change_role?
    UserPolicy.new(user).destroy?

    UserPolicy.new(user).view?(other_user)
    UserPolicy.new(user).edit_basic_info?(other_user)
    UserPolicy.new(user).change_role?(other_user)
    UserPolicy.new(user).email?(other_user)
  end

  it "limits lookup methods to contexts with and without objects appropriately" do
    user = User.create!
    other_user = User.create!

    assert_raises(ArgumentError) do
      UserPolicy.new(user).email?
    end

    assert_raises(ArgumentError) do
      UserPolicy.new(user).destroy?(other_user)
    end
  end

  it "requires object_type to be defined" do
    assert_raises(NotImplementedError) do
      PolicyWithoutObjectType.new(User.new).view?
    end
  end

  it "looks up non-object permissions from the Accessly library" do
    user = User.create!

    UserPolicy.new(user).edit_basic_info?.must_equal false

    Accessly::PermittedAction.create!(
      id: SecureRandom.uuid,
      segment_id: -1,
      actor: user,
      action: 2,
      object_type: String(User)
    )

    UserPolicy.new(user).edit_basic_info?.must_equal true
  end

  it "caches non-object permission lookups" do
    user = User.create!
    policy = UserPolicy.new(user)

    policy.edit_basic_info?.must_equal false

    permission = Accessly::PermittedAction.create!(
      id: SecureRandom.uuid,
      segment_id: -1,
      actor: user,
      action: 2,
      object_type: String(User)
    )

    policy.edit_basic_info?.must_equal false

    policy = UserPolicy.new(user)
    policy.edit_basic_info?.must_equal true
    permission.destroy!
    policy.edit_basic_info?.must_equal true
  end

  it "looks up object permissions from the Accessly library" do
    user = User.create!
    other_user = User.create!

    UserPolicy.new(user).email?(other_user).must_equal false

    Accessly::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      segment_id: -1,
      actor: user,
      action: 4,
      object: other_user
    )

    UserPolicy.new(user).email?(other_user).must_equal true
  end

  it "caches object permission lookups" do
    user = User.create!
    other_user = User.create!
    policy = UserPolicy.new(user)

    policy.email?(other_user).must_equal false

    permission = Accessly::PermittedActionOnObject.create!(
      id: SecureRandom.uuid,
      segment_id: -1,
      actor: user,
      action: 4,
      object: other_user
    )

    policy.email?(other_user).must_equal false

    policy = UserPolicy.new(user)
    policy.email?(other_user).must_equal true
    permission.destroy!
    policy.email?(other_user).must_equal true
  end
end
