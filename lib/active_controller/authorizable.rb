module ActiveController
  module Authorizable
    self.included(base)
      base.extend(SingletonMethods)
    end
    module SingletonMethods
      def authorize(roles,actions)
          
      end
    end
