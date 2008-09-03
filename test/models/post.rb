class Post < ActiveRecord::Base
  acts_as_authorizable :role_class_name => 'Role', :role_locate_method => 'find_by_name'

  belongs_to :owner, :class_name => 'User'
  belongs_to :forum_thread
  
  auth_belongs_to_user :owner, :role => 'Post Owner'
  auth_belongs_to_parent :forum_thread
end
