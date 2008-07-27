# Site-specific parameters
# These are Mailr constants. If you want to overwrite
# some of them - create file config/site.rb
# containing new constants in LOCALCONFIG module variable - they
# will overwrite default values. Example site.rb:
# 
# module CDF
#   LOCALCONFIG = {
#     :mysql_version => '4.1',
#     :default_encoding => 'utf-8',
#     :imap_server => 'your.imap.server',
#     :imap_auth => 'LOGIN'
#   }
# end

module CDF
  CONFIG = {
  :mysql_version => '4.0',
  :default_language => 'en',
  :default_encoding => 'ISO-8859-1',
  :mail_charset => 'ISO-8859-1',
  :mail_inbox => 'INBOX',
  :mail_trash => 'INBOX.Trash',
  :mail_sent => 'INBOX.Sent',
  :mail_bulk_sent => "INBOX.SentBulk",
  :mail_spam => "INBOX.Spam",
  :mail_temp_path => 'mail_temp',
  :mail_filters_path => '/home/vmail/mailfilters',
  :mail_send_types => {"Plain text" => "text/plain", "HTML"=>"text/html", "HTML and PlainText" => "multipart"},
  :mail_message_rows => [5, 10, 15, 20, 25, 30, 50],
  :mail_filters_fields => {'From' => '^From', 'To' => '^To', 'CC' => '^CC', 'Subject' => '^Subject', 'Body' => '^Body'},
  :mail_filters_expressions => ['contains', 'starts with'],
  :mail_search_fields => ['FROM', 'TO', 'CC', 'SUBJECT', 'BODY'],
  :temp_file_location => ".",
  :contacts_per_page => 15,
  :contact_letters => ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'],
  :am_address        => "localhost", 
  :am_port           => 25, 
  :am_domain         => 'localhost.localdomain', 
  :am_user_name      => nil, 
  :am_password       => nil, 
  :am_authentication => nil,
  :upload_file_temp_path => "/tmp",
  :imap_server => 'localhost',
  :imap_use_ssl => false,
  :imap_port => 143,
  :imap_auth => 'PLAIN', # 'LOGIN'
  :encryption_salt => 'EnCr1p10n$@lt',
  :encryption_password => '$0MeEncr1pt10nP@a$sw0rd',
  :debug_imap => false
  }
end

