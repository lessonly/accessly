class User < ActiveRecord::Base
  belongs_to :group, inverse_of: :users
end
