#! /opt/local/bin/ruby

require 'optparse'
require 'config/environment_exposed'
require 'drb'
require 'rmail'
require 'mime/types'
require 'rein'

require 'pp'

require 'message_analyzer/message_handler'

#TODO: Make PDF handled
#TODO: handle OCR

#Define an object for the rules to act on to determine if a particular patient matches
class PatientRuleTarget
  attr :patient
  attr :matches
  attr :match

  def initialize( patient, matches )
    @patient = patient
    @matches = matches
    @match = false
  end

  def consider_as_matching
    @match = true
  end
end

class MessageRuleTarget
  attr :message
  attr :patient_match
  attr :action
  attr :log

  def initialize( message, patient_match )
    @message = message
    @patient_match = patient_match
    @action = :allow
    @log = false
  end

  def allow() @action = :allow end
  def block() @action = :block end
  def secure() @action = :secure end
  def allow_and_log() @action = :allow ; @log = true end
  def block_and_log() @action = :block ; @log = true end
  def secure_and_log() @action = :secure ; @log = true end
  def to_s() "Action: #{action} --- Log: #{log}" end
end

#Add support for includes operator to rules engine
class IncludesOperatorSupport
  def self::includes( left, right )
    left.include? right
  end
end
Rein::Qualifier.set_operator('includes', :includes, IncludesOperatorSupport)

#Begin the main message analyzer
class MessageAnalyzer
  MIME_HANDLERS = File.open("#{MEDIMAIL_ROOT}/config/mime_handlers.yml") { |f| YAML::load(f) }

  def self::analyze_message( file )
    email = File.open( file, 'r' ) { |f| RMail::Parser.read( f ) }

    patient_analysis = scan_email( email )

    #puts contents( email )

    matching_patients = determine_matching_patients( email, patient_analysis )
    message_engine = Rein::RuleEngine.new "#{MEDIMAIL_ROOT}/config/message_rules.yml"

    puts matching_patients.to_yaml

    rule_target = MessageRuleTarget.new( email, matching_patients.length > 0 )
    message_engine.fire rule_target

    rule_target
  end

  def self::determine_matching_patients( email, patient_analysis )
    #run rule engine to determine if we need to secure or document or can just pass through
    patient_engine = Rein::RuleEngine.new "#{MEDIMAIL_ROOT}/config/patient_rules.yml"
    matching_patients = []
    patient_analysis.each do |attachment_matches|
      attachment_matches.each do |match|
        rule_target = PatientRuleTarget.new( match[0], match[1] )
        patient_engine.fire rule_target
        matching_patients << [rule_target.patient, rule_target.matches] if rule_target.match
      end
    end

    matching_patients
  end

  private
  def self::scan_email( email )
    [ headers( email ), contents( email ) ].flatten.collect { |scannable| match_patients( scannable ) }
  end

  def self::headers( email )
    [ email.header.recipients.display_names, email.header.recipients.names, email.header.subject, email.header.from.display_names, email.header.from.names ].uniq.join("\n")
  end

  def self::contents( email )
    if email.multipart?
      parts = []
      email.each_part { |part| parts << part }
      parts.map do |part|
        mime_type = MIME::Types[ part.header.content_type ].first

        if ! MIME_HANDLERS[ mime_type.simplified ].nil?
          command_line = MIME_HANDLERS[ mime_type.simplified ]
          if command_line.include? '$1'
            puts "Handling attachment: #{mime_type}\n"
            temp_file = Tempfile.new( 'attachment' )
            File.open( temp_file.path, 'w' ) { |f| f << part.decode }
            `#{command_line.gsub( '$1', temp_file.path )}`
          else
            #Todo!! Fix this
            raise RuntimeException, 'Need to implement streaming for mime_handlers'
            IO.popen( command_line, 'w+' ) { |p| p << part.body }
          end
        elsif mime_type.ascii?
          part.decode
        else
          #breakpoint
          MEDIMAIL_DEFAULT_LOGGER.warn "Unhandled attachement #{mime_type}"
          "ATTACHEMENT: #{mime_type}\n"
        end
      end
    else
      email.body
    end
  end

  def self::match_patients( text )
    #MEDIMAIL_DEFAULT_LOGGER.debug "Scanning text:\n #{text}"
    patient_data_index.match_message( text )
  end

  def self::patient_data_index
    DRbObject.new( nil, PATIENT_DATA_INDEX_URL )
  end
end

file = nil
opts = OptionParser.new
opts.on( '-f FILE', '--file FILE', String ) { |val| file = val }
opts.parse( ARGV )

MessageHandler.handle_message( MessageAnalyzer.analyze_message( file ) )
