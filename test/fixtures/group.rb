class Group < ActiveRecord::Base
  has_many :users, inverse_of: :group
end
