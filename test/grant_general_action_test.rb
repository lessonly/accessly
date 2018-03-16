require 'test_helper'

describe AccessControl do

  it 'returns nil after a successful grant' do
    actor = User.create!

    assert_nil(AccessControl::Query.new(actor).grant(1, Post))
  end

  it 'returns nil after a duplicate grant with one record in the database' do
    actor = User.create!

    assert_nil(AccessControl::Query.new(actor).grant(1, Post))
    assert_nil(AccessControl::Query.new(actor).grant(1, Post))
    AccessControl::PermittedAction.where(actor: actor).count.must_equal 1
  end

  it 'raises an error when attempting to grant' do
    actor = User.create!

    assert_raises(AccessControl::CouldNotGrantError) do
      AccessControl::Query.new(actor).grant(nil, Post)
    end
  end
end
