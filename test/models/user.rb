class User < ActiveRecord::Base
  has_many :forum_memberships
end
