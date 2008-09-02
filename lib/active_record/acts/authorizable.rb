module ActiveRecord
  module Acts
    module Authorizable
      def self.included(base)
        base.extend(SingletonMethods)
      end
      module SingletonMethods
        #Signals that the model has some authorization information. Sets up the acts_as_authorizable_sources array.
        def acts_as_authorizable(options={})
          write_inheritable_attribute :acts_as_authorizable_sources, []
          class_inheritable_reader :acts_as_authorizable_sources
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
        #Determines if a user has the permission on the current model
        def authorized?(user,permission,excludes=[])
          return false if excludes.include?(self)
          excludes << self
          raise 'No authorizable sources' if acts_as_authorizable_sources.empty?
          acts_as_authorizable_sources.each do |source|
            case source[:type]
            when :belongs_to_user
              assoc = source[:association]
              if self.send(assoc) == user
                role_assoc = source[:role_association]
                if role_assoc.nil?
                  assoc_object = Role.locate(source[:role])
                  return true if !assoc_object.nil && assoc_object.allows?(permission)
                else
                  assoc_object = self.send(role_assoc)
                  return true if !assoc_object.nil? && assoc_object.allows?(permission)
                end
              end
            when :belongs_to_parent
              assoc = source[:association]
              assoc_object = self.send(assoc)
              return true if !assoc_object.nil? && assoc_object.authorized?(user,permission,excludes)
            when :has_many_parents
              assoc = source[:association]
              if source[:user_scope].nil?
                parents = self.send(assoc)
              else
                user_scope = source[:user_scope]
                parents = self.send(assoc).send(user_scope,user)
              end
              parents.each do |parent|
                return true if parent.authorized?(user,permission,excludes)
              end
            end
          end
          return false
        end
        def authorized_by(user,permission,excludes=[])
          return [] if excludes.include?(self)
          raise 'No authorizable sources' if acts_as_authorizable_sources.empty?
          roles = []
          acts_as_authorizable_sources.each do |source|
            case source[:type]
            when :belongs_to_user
              assoc = source[:association]
              if self.send(assoc) == user
                role_assoc = source[:role_association]
                if role_assoc.nil?
                  assoc_object = Role.locate(source[:role])
                  roles << assoc_object if !assoc_object.nil && assoc_object.allows?(permission)
                else
                  assoc_object = self.send(role_assoc)
                  roles << assoc_object if !assoc_object.nil? && assoc_object.allows?(permission)
                end
              end
            when :belongs_to_parent
              assoc = source[:association]
              assoc_object = self.send(assoc)
              roles.concat(assoc_object.authorized_by(user,permission,excludes)) if !assoc_object.nil? 
            when :has_many_parents
              assoc = source[:association]
              if source[:user_scope].nil?
                parents = self.send(assoc)
              else
                user_scope = source[:user_scope]
                parents = self.send(assoc).send(user_scope,user)
              end
              parents.each do |parent|
                roles.concat(parent.authorized_by(user,permission,excludes))
              end
            end
          end
          return roles.uniq
        end
        
        def authorized_by_paths(user,permission,path=[],excludes=[])
          return [] if excludes.include?(self)
          raise 'No authorizable sources' if acts_as_authorizable_sources.empty?
          auth_info = []
          acts_as_authorizable_sources.each do |source|
            case source[:type]
            when :belongs_to_user
              assoc = source[:association]
              if self.send(assoc) == user
                role_assoc = source[:role_association]
                if role_assoc.nil?
                  assoc_object = Role.locate(source[:role])
                  if !assoc_object.nil && assoc_object.allows?(permission)
                    p = path.clone
                    p << self
                    auth_info << {:path => p, :role => assoc_object }
                  end 
                else
                  assoc_object = self.send(role_assoc)
                  if !assoc_object.nil? && assoc_object.allows?(permission)
                    p = path.clone
                    p << self
                    auth_info << {:path => p, :role => assoc_object }
                  end
                end
              end
            when :belongs_to_parent
              assoc = source[:association]
              assoc_object = self.send(assoc)
              if !assoc_object.nil? 
                p = path.clone
                p << self
                auth_info.concat(assoc_object.authorized_by(user,permission,p,excludes))
              end
            when :has_many_parents
              assoc = source[:association]
              if source[:user_scope].nil?
                parents = self.send(assoc)
              else
                user_scope = source[:user_scope]
                parents = self.send(assoc).send(user_scope,user)
              end
              parents.each do |parent|
                p = path.clone
                p << self
                auth_info.concat(parent.authorized_by(user,permission,p,excludes))
              end
            end
          end
        end
        
        def authorizations(user,excludes=[])
          return [] if excludes.include?(self)
          raise 'No authorizable sources' if acts_as_authorizable_sources.empty?
          roles = []
          acts_as_authorizable_sources.each do |source|
            case source[:type]
            when :belongs_to_user
              assoc = source[:association]
              if self.send(assoc) == user
                role_assoc = source[:role_association]
                if role_assoc.nil?
                  assoc_object = Role.locate(source[:role])
                  roles << assoc_object if !assoc_object.nil?
                else
                  assoc_object = self.send(role_assoc)
                  roles << assoc_object if !assoc_object.nil?
                end
              end
            when :belongs_to_parent
              assoc = source[:association]
              assoc_object = self.send(assoc)
              roles.concat(assoc_object.authorizations(user,excludes)) if !assoc_object.nil? 
            when :has_many_parents
              assoc = source[:association]
              if source[:user_scope].nil?
                parents = self.send(assoc)
              else
                user_scope = source[:user_scope]
                parents = self.send(assoc).send(user_scope,user)
              end
              parents.each do |parent|
                roles.concat(parent.authorizations(user,excludes))
              end
            end
          end
          return roles.uniq
        end
      end
    end
  end
end
