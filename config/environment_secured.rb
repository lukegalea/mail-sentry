require 'config/environment'

#secured components can access the sensitive db stuff
require 'active_record'

%w(
  model
).map { |dir| "#{MEDIMAIL_ROOT}/#{dir}" }.select { |dir| File.directory?(dir) }.collect { |dir| Dir.new( dir ) }.each do |dir|
  dir.each { |file| require "#{dir.path}/#{file}" if file =~ /^.*\.rb$/ }
end

[ActiveRecord].each { |mod| mod::Base.logger ||= MEDIMAIL_DEFAULT_LOGGER }

ActiveRecord::Base.establish_connection( File.open("#{MEDIMAIL_ROOT}/config/database.yml") { |f| YAML::load(f) }[ MEDIMAIL_ENV ])