MEDIMAIL_ROOT = File.dirname(__FILE__) + "/../"
MEDIMAIL_ENV  = ENV['MEDIMAIL_ENV'] || 'development'

# Require libraries.
require 'rubygems'
require 'active_support'
require 'yaml'

# Environment-specific configuration.
require_dependency "#{MEDIMAIL_ROOT}/config/environments/#{MEDIMAIL_ENV}"

# Configure defaults if the included environment did not.
begin
  MEDIMAIL_DEFAULT_LOGGER = Logger.new("#{MEDIMAIL_ROOT}/log/#{MEDIMAIL_ENV}.log")
rescue StandardError
  MEDIMAIL_DEFAULT_LOGGER = Logger.new(STDERR)
  MEDIMAIL_DEFAULT_LOGGER.level = Logger::WARN
  MEDIMAIL_DEFAULT_LOGGER.warn(
    "MediMail Error: Unable to access log file. Please ensure that log/#{MEDIMAIL_ENV}.log exists and is chmod 0666. " +
    "The log level has been raised to WARN and the output directed to STDERR until the problem is fixed."
  )
end

# Include your app's configuration here:
