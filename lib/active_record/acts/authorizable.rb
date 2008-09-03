module ActiveRecord
  module Acts
    module Authorizable
      def self.included(base)
        base.extend(SingletonMethods)
      end
      module SingletonMethods
        #Signals that the model has some authorization information. Sets up the acts_as_authorizable_sources array.
        def acts_as_authorizable(options={})
          conf = {:role_class_name => 'Role',:role_locate_method => 'locate'}
          conf.update(options)
          write_inheritable_attribute :acts_as_authorizable_sources, []
          class_inheritable_reader :acts_as_authorizable_sources
          wite_inheritable_attribute :acts_as_authorizable_options, conf
          class_inheritable_reader :acts_as_authorizable_options
          extend ClassMethods
          include InstanceMethods
        end
        
        #Piggybacks an existing association to a user to look for permissions. Optionally takes either a hard-code role or a role association.
        def auth_belongs_to_user(assoc,options = {})
          conf = {:role => nil, :association => assoc, :role_association => nil}
          conf.update(options)
          raise 'Need a role or role_association option for belongs_to_user' if conf[:role].nil? && conf[:role_association].nil?
          raise 'Cannot have both a role and a role_association for belongs_to_user' if !conf[:role].nil? && !conf[:role_association].nil?
          conf[:type] = :belongs_to_user
          acts_as_authorizable_sources << conf
        end
        
        #Piggybacks an existing belongs_to association to look for permissions.
        def auth_belongs_to_parent(assoc,options = {})
          conf = {:association => assoc}
          conf.update(options)
          raise 'Need a parent association for has_many_parents' if conf[:association].nil?
          conf[:type] = :belongs_to_parent
          acts_as_authorizable_sources << conf
        end
        
        #Piggybacks an existing has_one association to look for permissions.
        def auth_has_one_parent(assoc,options = {})
          auth_belongs_to_parent(assoc,options)
        end
        
        #Piggybacks an existing has_many association to look for permissions. Optionally takes a scope which takes the user object as a parameter which weeds the has_many association. 
        def auth_has_many_parents(assoc,options = {})
          conf = {:association => assoc, :user_scope => nil}
          conf.update(options)
          raise 'Need a parent association for has_many_parents' if conf[:association].nil?
          conf[:type] = :has_many_parents
          acts_as_authorizable_sources << conf
        end
      end
      module ClassMethods
      end
      module InstanceMethods
        
        #Determines if a user has the permission on the current model instance
        def authorized?(user,permission,excludes=[])
          return false if excludes.include?(self)
          excludes << self
          auth_check_sources!
          acts_as_authorizable_sources.each do |source|
            case source[:type]
            when :belongs_to_user
              return true unless auth_using_belongs_to_user(source,user,permission).nil?
            when :belongs_to_parent
              assoc_object = self.send(source[:association])
              return true if !assoc_object.nil? && assoc_object.authorized?(user,permission,excludes)
            when :has_many_parents
              auth_assoc_using_has_many_parents(source).each do |parent|
                return true if parent.authorized?(user,permission,excludes)
              end
            end
          end
          return false
        end
        
        protected
        
        #Checks that there is a source
        def auth_check_sources!
          raise 'No authorizable sources' if acts_as_authorizable_sources.empty?
        end
        
        #Returns nil, or the role object representing the authorization from a belongs_to_user source
        def auth_using_belongs_to_user(source,user,permission)
          if auth_user_association_matches?(source[:association],user)
            if source[:role_association].nil?
              role_object = auth_locate_role_object(source[:role])
            else
              role_object = self.send(source[:role_association])
            end
            return role_object if !role_object.nil? && role_object.allows?(permission)
          end
          return nil
        end
        
        #Returns the association built from a auth_has_many_parents
        def auth_assoc_using_has_many_parents(source)
          assoc = source[:association]
          if source[:user_scope].nil?
            parents = self.send(assoc)
          else
            user_scope = source[:user_scope]
            parents = self.send(assoc).send(user_scope,user)
          end
          return parents
        end
        
        #Determines if the user_association matches a given user
        def auth_user_association_matches?(assoc,user)
          return self.send(assoc) == user
        end
        
        #Locates a role based on :role_class_name and :role_locate_method options
        def auth_locate_role_object(role)
          return acts_as_authorizable_options[:role_class_name].constantize.send(acts_as_authorizable_options[:role_locate_method],role)
        end
      end
    end
  end
end
