require 'test_helper'

describe AccessControl do
  it 'caches the result of general permitted action' do
    actor = User.create!
    query = AccessControl::Query.new(actor)
    query.can?(1, Post).must_equal false

    AccessControl::PermittedAction.create!(
      id: SecureRandom.uuid,
      actor: actor,
      action: 1,
      object_type: Post
    )

    query.can?(1, Post).must_equal false
    AccessControl::Query.new(actor).can?(1, Post).must_equal true
  end
end
