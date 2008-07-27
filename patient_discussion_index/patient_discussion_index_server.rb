#! /opt/local/bin/ruby

require 'config/environment_exposed' #Strangely enough, this doesn't need to be secured even though the plan was to put it somewhere secure
require 'drb'
require 'ferret'
include Ferret
include Ferret::Document

class PatientDiscussionIndexServer
  #attr :index
  MESSAGE_PROPERTIES = [ :message_id, :sent_date, :from, :to, :subject, :patient_firstname, :patient_lastname, :patient_mrn, :patient_healthcard ]
  MESSAGE_ID_PROPERTY = MESSAGE_PROPERTIES[0]
  
  def index_message( data = {} )
    MEDIMAIL_DEFAULT_LOGGER.debug "#{ data.to_yaml }" #Todo: replace with injection
    doc = Document.new
    MESSAGE_PROPERTIES.each do |prop| 
      doc << Field.new( prop.to_s, data[prop], prop == MESSAGE_ID_PROPERTY ? Field::Store::YES : Field::Store::NO, Field::Index::TOKENIZED )
    end
    @index << doc
  end
  
  def search( query )
    @index.search( query ).to_yaml
  end
  
  private
  def initialize
    build_indexes
  end
  
  #Pulls data from somewhere
  def build_indexes
    @index = Index::Index.new( :path => PATIENT_DISCUSSION_INDEX_PERSISTENT_STORE_FILEPATH, :create => true )
    
    #TODO: We need a message database. We can assume that all the messages in the discussion db are in the index
  end
end

server = PatientDiscussionIndexServer.new
DRb.start_service( PATIENT_DISCUSSION_INDEX_URL, server )
puts "Patient Discussion Index Service Start at #{PATIENT_DISCUSSION_INDEX_URL}"
MEDIMAIL_DEFAULT_LOGGER.info "Patient Discussion Index Service Start at #{PATIENT_DISCUSSION_INDEX_URL}"
DRb.thread.join