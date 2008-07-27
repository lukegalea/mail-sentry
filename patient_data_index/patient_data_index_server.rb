#! /usr/bin/ruby

require 'config/environment_secured' #TODO: Make it 'exposable' by removing db access
require 'drb'
require 'lib/bsearch'
require 'models/patient_model'

#Note: Not sure if the server should go to the database and pull, or if an interface should push to the server
#either way, there will be no patient data on the secure server.
#ideally postgres would do magic on the other end

class PatientDataIndexServer
  EXCLUSIONS = File.open("#{MEDIMAIL_ROOT}/config/patient_data_index_exclusions.yml") { |f| YAML::load(f) }

  def match_message( message = '' )
    match_words message.scan( /\w+/ ).collect { |word| word.downcase }
  end

  def match_words( words = [] )
    patient_matches = {}
    @indexes.each_pair do |col, index|
      words.each do |word|
        word_hash = word.hash
        match_range = index.bsearch_range { |patient| patient[0] <=> word_hash }
        index[ match_range ].each { |patient| ( patient_matches[ patient[1] ] ||= [] ) << col }
      end
    end

    patient_matches.each_pair { |patient, match_cols| match_cols.uniq! }
    patient_matches
  end

  private
  def initialize
    @indexes = {}
    build_indexes
  end

  #Pulls data from database
  def build_indexes
    Patient.column_names.select { |col| col != 'id' }.each do |col|
      @indexes[ col.to_sym ] = []
    end

    Patient.find( :all ).each do |patient|
      Patient.column_names.select { |col| col != 'id' }.each do |col|
        @indexes[ col.to_sym ] << [ patient.send( col ).to_s.strip.hash, patient.id ] unless
          ( (! EXCLUSIONS[ col ].nil?) and EXCLUSIONS[ col ].include? patient.send( col ).to_s.strip )
      end
    end

    @indexes.each_value { |value| value.sort! { |a,b| a[0] <=> b[0] } }
  end
end

server = PatientDataIndexServer.new
DRb.start_service( PATIENT_DATA_INDEX_URL, server )
puts "Patient Data Index Service Start at #{PATIENT_DATA_INDEX_URL}"
MEDIMAIL_DEFAULT_LOGGER.info "Patient Data Index Service Start at #{PATIENT_DATA_INDEX_URL}"
#MEDIMAIL_DEFAULT_LOGGER.info "Index length: #{server.index.length}"
DRb.thread.join
