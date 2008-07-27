require_dependency 'maildropserializator'
class Customer < ActiveRecord::Base
  include MaildropSerializator
  
  has_many :filters, :order => "order_num"
  has_one :mail_pref
  attr_accessor :password
  
  def mail_temporary_path
    "#{CDF::CONFIG[:mail_temp_path]}/#{self.email}"
  end
  
  def friendlly_local_email
    encode_email("#{self.fname} #{self.lname}", email)
  end
  
  def mail_filter_path
    "#{CDF::CONFIG[:mail_filters_path]}/#{self.email}"
  end

  def local_email
    self.email
  end
end
