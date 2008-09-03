require "#{File.dirname(__FILE__)}/lib/authorizable"
ActiveRecord::Base.send(:include, ActiveRecord::Acts::Authorizable)
