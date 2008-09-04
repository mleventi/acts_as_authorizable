require File.dirname(__FILE__) + "/test_helper"

class ActsAsAuthorizableTest < Test::Unit::TestCase
  fixtures :users, :forums, :forum_memberships, :forum_threads, :roles, :posts
  
  #Tests that options are set correctly
  def test_acts_as_authorizable_options
    assert_equal 'Role', Forum.acts_as_authorizable_options[:role_class_name]
    assert_equal 'find_by_name', Forum.acts_as_authorizable_options[:role_locate_method]
  end
  
  #Tests that sources is an array with appropriate sizes
  def test_acts_as_authorizable_sources_size
    assert_equal 2, Post.acts_as_authorizable_sources.size
    assert_equal 1, ForumMembership.acts_as_authorizable_sources.size 
  end
  
  #Tests that sources is lexically ordered
  def test_acts_as_authorizable_sources_lexical_ordering
    assert_equal :belongs_to_user, Post.acts_as_authorizable_sources.first[:type]
    assert_equal :belongs_to_parent, Post.acts_as_authorizable_sources.last[:type]
  end
  
  #Tests that sources is getting belongs_to_user role associated properly
  def test_acts_as_authorizable_sources_auth_belongs_to_user_with_role_association
    assert_equal :belongs_to_user, ForumMembership.acts_as_authorizable_sources.first[:type]
    assert_equal :user, ForumMembership.acts_as_authorizable_sources.first[:association]
    assert_equal :role, ForumMembership.acts_as_authorizable_sources.first[:role_association]
    assert_nil ForumMembership.acts_as_authorizable_sources.first[:role]
  end
  
  #Tests that sources is getting belongs_to_user hardcoded
  def test_acts_as_authorizable_sources_auth_belongs_to_user_with_role_hardcoded
    assert_equal 'Post Owner', Post.acts_as_authorizable_sources.first[:role] 
  end
  
  #Tests that sources is getting belongs_to_parent properly
  def test_acts_as_authorizable_sources_auth_belongs_to_parent
    assert_equal :forum_thread, Post.acts_as_authorizable_sources.last[:association]
  end
  
  #Tests that sources is getting has_many parents properly
  def test_acts_as_authorizable_sources_auth_has_many_parents
    assert_equal :forum_memberships, Forum.acts_as_authorizable_sources.first[:association]
  end
  
  #Tests that sources is getting has_many parents properly with scope
  def test_acts_as_authorizable_sources_auth_has_many_parents_scoped
    assert_equal :with_user, Forum.acts_as_authorizable_sources.first[:user_scope]
  end
  
  #Tests that auth_user_association_matches? works
  def test_auth_user_association_matches
    u = User.find_by_name('Dave')
    u2 = User.find_by_name('Matt')
    f = u.forum_memberships.first
    assert f.send('auth_user_association_matches?',:user,u )
    assert !f.send('auth_user_association_matches?',:user,u2 )
  end
  
  #Tests that auth_locate_role_object works
  def test_auth_locate_role_object
    r = Role.find_by_name('Post Owner')
    p = Post.first
    assert_equal r, p.send('auth_locate_role_object','Post Owner')
  end
  
  #Tests that auth_assoc_using_has_many_parents works with scope
  def test_auth_assoc_using_has_many_parents
    f = Forum.find_by_name("Support")
    u = User.find_by_name("Matt")
    assoc = f.send('auth_assoc_using_has_many_parents',f.acts_as_authorizable_sources.first,u)
    assert_equal 1, assoc.size
    assert_equal 'Forum Moderator', assoc.first.role.name
  end
  
  #Tests that auth_using_belongs_to_user fetches the correct role object
  def test_auth_using_belongs_to_user
    p = Post.first
    u = User.find_by_name('Matt')
    u2 = User.find_by_name('Dave')
    assert_equal 'Post Owner', p.send('auth_using_belongs_to_user',Post.acts_as_authorizable_sources.first,u,'owns').name
    assert_nil p.send('auth_using_belongs_to_user',Post.acts_as_authorizable_sources.first,u2,'owns')
    assert_nil p.send('auth_using_belongs_to_user',Post.acts_as_authorizable_sources.first,u,'ow2ns')
  end
  
  #Tests a direct authorization using a belongs_to_user
  def test_direct_authorization
    u = User.find_by_name('Matt')
    m = u.forum_memberships.first
    assert m.authorized?(u,'moderate')
  end
  
  #Tests a indirect authorization using a belongs_to_parent scoped
  def test_indirect_authorization
    u = User.find_by_name('Matt')
    f = u.forum_memberships.first.forum
    assert f.authorized?(u,'moderate')
  end
  
  #Tests a long authorization using two hops with other branches
  def test_very_indirect_authorization
    u = User.find_by_name('Matt')
    t = u.forum_memberships.first.forum.forum_threads.first
    assert t.authorized?(u,'moderate') 
  end
end
