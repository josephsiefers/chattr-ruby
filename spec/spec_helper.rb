$LOAD_PATH.unshift "#{Dir.pwd}/lib/"
require 'json'
require 'yaml'
require 'erb'
require 'active_record'
require 'database_cleaner'
require 'factory_girl'

#allow ERB strings in database config file
config = JSON.parse(ERB.new(YAML.load_file('db/config.yml').to_json).result)["development"]
ActiveRecord::Base.establish_connection(config)

DatabaseCleaner.strategy = :transaction

RSpec.configure do |config|
	config.before(:each) do
		DatabaseCleaner.start
	end

	config.after(:each) do
		DatabaseCleaner.clean
	end

	config.include FactoryGirl::Syntax::Methods

	config.before(:suite) do
	    FactoryGirl.find_definitions
	end
end