#! /opt/local/bin/ruby

require 'config/environment.rb'
require 'faster_csv'
#require 'patient_data_index/patient_model'

PATIENT_FILE = 'data/medimail_dev.csv'

FasterCSV.foreach( PATIENT_FILE ) do |row|
  row.each do |col|
    col.strip! unless col.nil?
    col.downcase! unless col.nil?
  end

  puts 'booya'

  mrn = ActiveRecord::Base.connection.select_one( "CALL load_value( '#{row[1]}', 'mrn', '#{row[1]}', NULL, 'Patient', 'Toronto Rehab' );" )
  ActiveRecord::Base.connection.execute( "CALL load_value( '#{row[2]}', 'firstname', '#{row[1]}', #{mrn}, 'Patient', 'Toronto Rehab' );" )
  ActiveRecord::Base.connection.execute( "CALL load_value( '#{row[3]}', 'lastname', '#{row[1]}', #{mrn}, 'Patient', 'Toronto Rehab' );" )
  ActiveRecord::Base.connection.execute( "CALL load_value( '#{row[4]}', 'healthcard', '#{row[1]}', #{mrn}, 'Patient', 'Toronto Rehab' );" )
end