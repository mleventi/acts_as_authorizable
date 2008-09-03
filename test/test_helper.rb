RAILS_ROOT = File.dirname(__FILE__)
 
require "rubygems"
require "test/unit"
require "active_record"
require "active_record/fixtures"


$:.unshift File.dirname(__FILE__) + "/../lib"
require File.dirname(__FILE__) + "/../init"

require File.dirname(__FILE__) + "/models/user"
require File.dirname(__FILE__) + "/models/post"
require File.dirname(__FILE__) + "/models/role"
require File.dirname(__FILE__) + "/models/forum_thread"
require File.dirname(__FILE__) + "/models/forum"
require File.dirname(__FILE__) + "/models/forum_membership"


require "stringio"
$LOG = StringIO.new
$LOGGER = Logger.new($LOG)
ActiveRecord::Base.logger = $LOGGER
 
ActiveRecord::Base.configurations = {
  "sqlite" => {
    :adapter => "sqlite",
    :dbfile => "acts_as_authorizable.sqlite.db"
  },
 
  "sqlite3" => {
    :adapter => "sqlite3",
    :dbfile => "acts_as_authorizable.sqlite3.db"
  },
 
  "mysql" => {
    :adapter => "mysql",
    :host => "localhost",
    :username => "rails",
    :password => nil,
    :database => "acts_as_authorizable_test"
  },
 
  "postgresql" => {
    :min_messages => "ERROR",
    :adapter => "postgresql",
    :username => "postgres",
    :password => "postgres",
    :database => "acts_as_authorizable_test"
  }
}
 
# Connect to the database.
ActiveRecord::Base.establish_connection(ENV["DB"] || "sqlite3")
 
# Create table for conversations.
ActiveRecord::Migration.verbose = false
ActiveRecord::Schema.define(:version => 1) do
  create_table :forums, :force => true do |t|
    t.string :name
  end
  
  create_table :forum_memberships, :force => true do |t|
    t.references :forum
    t.references :user
    t.references :role
  end
  
  create_table :forum_threads, :force => true do |t|
    t.integer :moderator_id
    t.references :forum
    t.string :name
  end
  
  create_table :posts, :force => true do |t|
    t.integer :owner_id
    t.references :forum_thread
    t.string :name
  end
  
  create_table :roles, :force => true do |t|
    t.string :name
    t.text :permissions
  end
  
  create_table :users, :force => true do |t|
    t.string :name
  end
end

class Test::Unit::TestCase
  self.fixture_path = File.dirname(__FILE__) + "/fixtures/"
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures = false
 
  def create_fixtures(*table_names, &block)
    Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names, &block)
  end
end
