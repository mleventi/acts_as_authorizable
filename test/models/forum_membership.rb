class ForumMembership < ActiveRecord::Base
  acts_as_authorizable
  
  named_scope :with_user, lambda { |user| {:conditions => {:user_id => user}}}
  
  belongs_to :forum
  belongs_to :role
  belongs_to :user
  
  auth_belongs_to_user :user, :role_association => :role
end
