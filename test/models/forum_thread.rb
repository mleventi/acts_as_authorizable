class ForumThread < ActiveRecord::Base
  acts_as_authorizable :role_class_name => 'Role', :role_locate_method => 'find_by_name'
  
  belongs_to :forum
  belongs_to :moderator, :class_name => 'User'
  
  has_many :posts
  
  auth_belongs_to_user :moderator, :role => 'Thread Moderator'
  auth_belongs_to_parent :forum
  
end
