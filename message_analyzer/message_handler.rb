class MessageHandler
  def self::handle_message( analysis = MessageRuleTarget.new )
    if analysis.log
      log( analysis )
    end

    self::send( analysis.action, analysis )
  end

  private

  def self::log( analysis )
    puts analysis
  end

  def self::allow( analysis )
    #todo: how do I allow a message?
    puts 'ALLOWING'
  end

  def self::block( analysis )
    #todo: how do I block a message?
    puts 'BLOCKING'
  end

  def self::secure( analysis )
    analysis.message.header.to.collect { |to| find_or_create_recipient( to.address.downcase ) }.each do |recipient|
      if maildirs_exists? to
        inject_message_into_maildirs( recipient, message )
        send_new_message_notification( recipient, analysis )
      else
        inject_message_into_pending_db( recipient, analysis )
        send_sender_challenge_response( recipient, analysis )
      end
    end
  end

  def self::find_or_create_recipient( to )
    #Go into the database and make sure an entry exists
    #return the entry
  end

  def self::inject_message_into_pending_db( recipient, analysis )
    #The db will be recipients -> pending_messages
    recipient.messages << analysis.message
  end

  def self::send_new_message_notification( recipient, analysis )
    #todo: soap/druby call to challenge/response rails app
  end

  def self::send_sender_challenge_response( recipient, analysis )
    #todo: soap/druby call to challenge/response rails app
  end
end