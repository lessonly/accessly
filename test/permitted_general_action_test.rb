require "test_helper"

describe AccessControl do
  it "returns false when actor lacks access" do
    actor = User.create!

    AccessControl::Query.new(actor).can?(1, Post).must_equal false
  end

  it "retuns true when the actor has access" do
    actor = User.create!

    AccessControl::PermittedAction.create!(
      id: SecureRandom.uuid,
      actor: actor,
      action: 1,
      object_type: Post
    )

    AccessControl::Query.new(actor).can?(1, Post).must_equal true
  end
end
