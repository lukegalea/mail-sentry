#! /opt/local/bin/ruby

require 'config/environment_secured.rb'
require 'faster_csv'
require 'models/patient_model'

PATIENT_FILE = 'data/patients.csv'

Patient.destroy_all

FasterCSV.foreach( PATIENT_FILE ) do |row|
  row.each do |col| 
    col.strip! unless col.nil?
    col.downcase! unless col.nil?
  end
  
  Patient.new( :mrn => row[0], :firstname => row[1], :lastname => row[2], :healthcard => row[3] ).save!
end
