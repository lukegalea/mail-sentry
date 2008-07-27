#! /opt/local/bin/ruby

require 'config/environment_secured'
require 'drb'
require 'test/unit'
#require 'patient_data_index/patient_model'
require 'yaml'

DRb.start_service

class TC_PatientDataIndex < Test::Unit::TestCase
  EMAIL_FILE = 'test/messages/email.eml'
  EMAIL = File.open( EMAIL_FILE, 'r' ) { |f| f.read }
  
  def test_match_message
    assert_nothing_raised do
      patient_data_index.match_message( EMAIL ).select { |patient, matches| matches.length > 1 }      
    end
  end
  
  def test_discussion_index_message
    #Go first and determine which patient is being discussed, then index it
    matches = nil
    
    assert_nothing_raised do
      matches = patient_data_index.match_message( File.open( EMAIL_FILE, 'r' ) { |f| f.read } ).select { |patient, matches| matches.length > 1 }
    end
      
    assert_not_equal( matches.length, 0 )
      
    #arbitrarily decide that anything with 3 or more hits is a "HIT".. rules engine would handle this normally
    assert_nothing_raised do
      patients = matches.select { |patient_id, matches| matches.length > 2 }.collect { |patient_id, matches| patient_id }.map do |patient_id|
        patient = Patient.find( patient_id )
        patient_discussion_index.index_message( :message_id => 0, :sent_date => Date.today, :from => 'galea.luke@torontorehab.on.ca', 
            :to => 'jcmcafee@rogers.com', :patient_firstname => patient.firstname, :patient_lastname => patient.lastname, :patient_mrn => patient.mrn,
            :patient_healthcard => patient.healthcard )
      end
    end
  end
  
  def test_discussion_search
    puts patient_discussion_index.search( "'martha'" ).to_yaml
  end
  
  private
  def patient_data_index
    DRbObject.new( nil, PATIENT_DATA_INDEX_URL )
  end
  
  def patient_discussion_index
    DRbObject.new( nil, PATIENT_DISCUSSION_INDEX_URL )
  end
end