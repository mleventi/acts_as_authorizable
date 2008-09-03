class Forum < ActiveRecord::Base
  acts_as_authorizable
  
  has_many :forum_memberships
  has_many :forum_threads
  
  auth_has_many_parents :forum_memberships, :user_scope => :with_user
end
