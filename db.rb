require 'bundler'
Bundler.setup(:default, (ENV['RACK_ENV'] || :development).to_sym)

begin
  require_relative '.env.rb'
rescue LoadError
end

require 'sequel/core'

# Delete APP_DATABASE_URL from the environment, so it isn't accidently
# passed to subprocesses.  APP_DATABASE_URL may contain passwords.
DB = Sequel.connect(ENV.delete('APP_DATABASE_URL') || ENV.delete('DATABASE_URL'))
