require "#{File.dirname(__FILE__)}/lib/active_record/acts/authorizable"
ActiveRecord::Base.send(:include, ActiveRecord::Acts::Authorizable)
