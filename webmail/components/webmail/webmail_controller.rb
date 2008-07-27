require 'cdfmail'
require 'net/smtp'
require 'net/imap'
require 'mail2screen'
require 'ezcrypto'

class Webmail::WebmailController < ApplicationController
  uses_component_template_root

  # Administrative functions
  before_filter :login_required
  
  before_filter :obtain_cookies_for_search_and_nav, :only=>[:messages]

  layout "public", :except => [:view_source, :download]
  
  before_filter :load_imap_session
  
  after_filter :close_imap_session
  
  model :filter, :expression, :mail_pref, :customer

	BOOL_ON = "on"

  def index
    redirect_to(:action=>"messages")
  end
  
  def error_connection
  end

  def refresh
    @mailbox.reload
    @folders = @mailbox.folders
    redirect_to(:action=>'messages')
  end
  
  def manage_folders
    if operation_param == _('Add folder')
      @mailbox.create_folder(CDF::CONFIG[:mail_inbox]+"."+@params["folder_name"])
    elsif operation_param == _('(Delete)')
      @mailbox.delete_folder(@params["folder_name"])
    elsif operation_param == _('(Subscribe)')
    elsif operation_param == _('(Select)')
    end
    @folders = @mailbox.folders
  end
  
  def messages
    @session["return_to"] = nil
    @search_field = @params['search_field']
    @search_value = @params['search_value']
    
    # handle sorting - tsort session field contains last reverse or no for field
    # and lsort - last sort field
    if @session['tsort'].nil? or @session['lsort'].nil?
      @session['lsort'] = "DATE"
      @session['tsort'] = {"DATE" => true, "FROM" => true, "SUBJECT" => true, "TO" => false}
    end
    
    case operation_param
      when _('copy') # copy
        msg_ids = []
        messages_param.each { |msg_id, bool| 
                      msg_ids << msg_id.to_i if bool == BOOL_ON and dst_folder != @folder_name }  if messages_param
        folder.copy_multiple(msg_ids, dst_folder) if msg_ids.size > 0 
      when _('move') # move
        msg_ids = []
        messages_param.each { |msg_id, bool| 
                      msg_ids << msg_id.to_i if bool == BOOL_ON and dst_folder != @folder_name } if messages_param
        folder.move_multiple(msg_ids, dst_folder) if msg_ids.size > 0 
      when _('delete') # delete
        msg_ids = []
        messages_param.each { |msg_id, bool| msg_ids << msg_id.to_i if bool == BOOL_ON } if messages_param
        folder.delete_multiple(msg_ids) if msg_ids.size > 0
      when _('mark read') # mark as read
        messages_param.each { |msg_id, bool| msg = folder.mark_read(msg_id.to_i) if bool == BOOL_ON }  if messages_param
      when _('mark unread') # mark as unread
        messages_param.each { |msg_id, bool| msg = folder.mark_unread(msg_id.to_i) if bool == BOOL_ON }  if messages_param
      when "SORT"
        @session['lsort'] = sort_query = @params["scc"]
        @session['tsort'][sort_query] = (@session['tsort'][sort_query]? false : true)
        @search_field, @search_value = @session['search_field'], @session['search_value']
      when _('Search') # search  
        @session['search_field'] = @search_field
        @session['search_value'] = @search_value
      when _('Show all') # search  
        @session['search_field'] = @search_field = nil
        @session['search_value'] = @search_value = nil
      else
        # get search criteria from session
        @search_field = @session['search_field']
        @search_value = @session['search_value']
    end
    
    sort_query = @session['lsort']
    reverse_sort = @session['tsort'][sort_query]
    query = ["ALL"]
    @page = @params["page"]
    @page ||= @session['page']
    @session['page'] = @page
    if @search_field and @search_value and not(@search_field.strip() == "") and not(@search_value.strip() == "")
      @pages = Paginator.new self, 0, get_mail_prefs.wm_rows, @page
      @messages = folder.messages_search([@search_field, @search_value], sort_query + (reverse_sort ? ' desc' : ' asc'))
    else
      @pages = Paginator.new self, folder.total, get_mail_prefs.wm_rows, @page
      @messages = folder.messages(@pages.current.first_item - 1, get_mail_prefs.wm_rows, sort_query + (reverse_sort ? ' desc' : ' asc'))
    end
    
  end
  
  def delete
    @msg_id = msg_id_param.to_i
    folder.messages().delete(@msg_id)
    redirect_to(:action=>"messages")
  end
  
  def reply # not ready at all
    @msg_id = msg_id_param.to_i
    @imapmail = folder.message(@msg_id)
    fb = @imapmail.full_body
    @tmail = TMail::Mail.parse(fb) 
    
    @mail = prepare_mail
    @mail.reply(@tmail, fb, get_mail_prefs.mail_type)
    
    render_action("compose")
  end
  
  def forward
    @msg_id = msg_id_param.to_i
    @imapmail = folder.message(@msg_id)
    fb = @imapmail.full_body
    @tmail = TMail::Mail.parse(fb) 
    
    @mail = prepare_mail
    @mail.forward(@tmail, fb)
    
    render_action("compose")
  end
   
  def compose
    if @mail.nil?
    	operation = operation_param
      if operation == _('Send')
	      @mail = create_mail
	      encmail = @mail.send_mail
	      get_imap_session
	      @mailbox.message_sent(encmail)
	     
	      # delete temporary files (attachments)
	      @mail.delete_attachments()
	      return render("webmail/webmail/mailsent")
	    elsif operation == _('Add')
	      @mail = create_mail
	      attachment = CDF::Attachment.new(@mail)
	      attachment.file = @params['attachment']
	    else
	      # default - new email create
	      @mail = create_mail
	    end
	  end
  end
  
  def empty # empty trash folder (works for any one else :-))
    folder.messages().each{ |message|
      folder.delete(message)
    }
    folder.expunge
    redirect_to(:action=>"messages")
  end
  
  def message
    @msg_id = msg_id_param
    @imapmail = folder.message(@msg_id)
    folder.mark_read(@imapmail.uid) if @imapmail.unread
    @mail = TMail::Mail.parse(@imapmail.full_body)
  end
  
  def download
    msg_id = msg_id_param
    imapmail = folder.message(msg_id)
    mail = TMail::Mail.parse(imapmail.full_body) 
    
    if mail.multipart?
      get_parts(mail).each { |part|  
      	return send_part(part) if part.header and part.header['content-type']['name'] == @params['ctype'] 
      }
      render("webmail/webmail/noattachment")
    else  
      render("webmail/webmail/noattachment")
    end  
  end
  
  def prefs
    @customer = Customer.find(logged_customer)
    if not(@mailpref = MailPref.find_by_customer(logged_customer))
      @mailpref = MailPref.create("customer_id"=>logged_customer)
    end

    if @params['op'] == _('Save')
      if @params['customer']
        @customer.fname = @params['customer']['fname']
        @customer.lname = @params['customer']['lname']
        @customer.save
      end
      @mailpref.attributes = @params["mailpref"]      
      @mailpref.save
      @session["wmimapseskey"] = nil
      redirect_to(:action=>"messages")
    end
  end
  
  # Message filters management
  def filters
  end
  
  def filter
    if @params['op']
      @filter = Filter.new(@params['filter'])
      @filter.customer_id = logged_customer
      @params['expression'].each { |index, expr| @filter.expressions << Expression.new(expr) unless expr["expr_value"].nil? or expr["expr_value"].strip == ""  }
      case @params['op']
        when _('Add')
          @filter.expressions << Expression.new
        when _('Save')  
          if @params['filter']['id'] and @params['filter']['id'] != ""
            @sf = Filter.find(@params['filter']['id'])
            @sf.name, @sf.destination_folder = @filter.name, @filter.destination_folder
            @sf.expressions.each{|expr| Expression.delete(expr.id) }
            @filter.expressions.each {|expr| @sf.expressions << Expression.create(expr.attributes) }
          else
            @sf = Filter.create(@filter.attributes)
            @sf.order_num = @user.filters.size
            @filter.expressions.each {|expr| @sf.expressions << Expression.create(expr.attributes) }
          end
          # may be some validation will be needed
          @sf.save
          @user.serialize_to_file
          return redirect_to(:action=>"filters")
        end
      @expressions = @filter.expressions
    else
      @filter = Filter.find(@params["id"]) if @params["id"]
      @expressions = @filter.expressions  
    end
    @destfolders = get_to_folders
  end
  
  def filter_delete
    Filter.delete(@params["id"])
    # reindex other filters
    @user = Customer.find(logged_customer)
    findex = 0
    @user.filters.each { |filter|
      findex = findex + 1
      filter.order_num = findex
      filter.save
    }
    @user.serialize_to_file
    redirect_to :action=>"filters"
  end
  
  def filter_up
    filt = @user.filters.find(@params['id'])
    ufilt = @user.filters.find_all("order_num = #{filt.order_num - 1}").first
    ufilt.order_num = ufilt.order_num + 1
    filt.order_num = filt.order_num - 1
    ufilt.save
    filt.save
    @user.serialize_to_file
    redirect_to :action=>"filters"
  end
  
  def filter_down
    filt = Filter.find(@params["id"])
    dfilt = @user.filters[filt.order_num]
    dfilt.order_num = dfilt.order_num - 1
    filt.order_num = filt.order_num + 1
    dfilt.save
    filt.save
    @user.serialize_to_file
    redirect_to :action=>"filters"
  end
  
  def filter_add
    @filter = Filter.new
    @filter.expressions << Expression.new
    @expressions = @filter.expressions
    @destfolders = get_to_folders
    render_action("filter")
  end
  # end of filters
  
  def view_source
    @msg_id = msg_id_param.to_i
    @imapmail = folder.message(@msg_id)
    @msg_source = CGI.escapeHTML(@imapmail.full_body).gsub("\n", "<br/>")
  end
  
  def auto_complete_for_mail_to
    auto_complete_responder_for_contacts params[:mail][:to]
  end
  
  def auto_complete_for_mail_cc
    auto_complete_responder_for_contacts params[:mail][:cc]
  end
  
  def auto_complete_for_mail_bcc
    auto_complete_responder_for_contacts params[:mail][:bcc]
  end
  
  private
  
  def auto_complete_responder_for_contacts(value)
    # first split by "," and take last name
    searchName = value.split(',').last.strip
    
    # if there are 2 names search by them
    if searchName.split.size > 1
      fname, lname = searchName.split.first, searchName.split.last
      conditions = ['customer_id = ? and LOWER(fname) LIKE ? and LOWER(lname) like ?', logged_customer, fname.downcase + '%', lname.downcase + '%']
    else
      conditions = ['customer_id = ? and LOWER(fname) LIKE ?', logged_customer, searchName.downcase + '%']
    end  
    @contacts = Contact.find(:all, 
        :conditions => conditions, 
        :order => 'fname ASC',
        :limit => 8)
    render :partial => 'contacts'
  end
  
  protected
  
  def additional_scripts()
    '<link rel="stylesheet" href="/stylesheets/webmail/webmail.css" type="text/css" media="screen" />'<<
    '<script type="text/javascript" src="/javascripts/webmail.js"></script>'
  end
  
  private
  
  def get_upass
    EzCrypto::Key.decrypt_with_password(CDF::CONFIG[:encryption_password], CDF::CONFIG[:encryption_salt], @session["wmp"])
  end  
  
  def get_to_folders
    res = Array.new
    @folders.each{|f| res << f unless f.name == CDF::CONFIG[:mail_sent] or f.name == CDF::CONFIG[:mail_inbox] }
    res
  end
  
  def load_imap_session
    return if ['compose', 'prefs', 'error_connection'].include?(action_name)
    get_imap_session
  end
  
  def get_imap_session
    begin
      @mailbox = IMAPMailbox.new
      uname = (get_mail_prefs.check_external_mail == 1 ? user.email : user.local_email)
      upass = get_upass
      @mailbox.connect(uname, upass)
      load_folders
    rescue Exception => ex
      logger.error("Exception on loggin webmail session - #{ex} - #{ex.backtrace.join("\t\n")}")
      render_action "error_connection"
    end   
  end
  
  def close_imap_session
  	return if @mailbox.nil? or not(@mailbox.connected)
  	@mailbox.disconnect
  	@mailbox = nil
  end
  
  def have_to_load_folders?
    return true if ['messages', 'delete', 'reply', 'forward', 'empty', 'message', 'download',
                 'filter', 'filter_add', 'view_source'].include?(action_name)
    return false
  end
  
  def load_folders
    if have_to_load_folders?()
      if @params["folder_name"]
        @folder_name = @params["folder_name"]
      else
        @folder_name = @session["folder_name"] ? @session["folder_name"] : CDF::CONFIG[:mail_inbox]
      end
      @session["folder_name"] = @folder_name
      @folders = @mailbox.folders if @folders.nil?
    end  
  end
  
  def create_mail
    m = CDF::Mail.new(user.mail_temporary_path)
    if @params["mail"]
      ma = @params["mail"]
      m.body, m.content_type, m.from, m.to, m.cc, m.bcc, m.subject =  ma["body"], ma["content_type"], ma["from"], ma["to"], ma["cc"], ma["bcc"], ma["subject"]
      if @params["att_files"]
        att_files, att_tfiles, att_ctypes = @params["att_files"], @params["att_tfiles"], @params["att_ctypes"]
        att_files.each {|i, value|
          att = CDF::Attachment.new(m)
          att.filename, att.temp_filename, att.content_type = value, att_tfiles[i], att_ctypes[i]
        }
      end
    else
      m.from, m.content_type = user.friendlly_local_email, get_mail_prefs.mail_type
    end 
    m.customer_id = logged_customer
    m
  end
  
  def prepare_mail
    m = CDF::Mail.new(user.mail_temporary_path)
    m.from, m.content_type = user.friendlly_local_email, get_mail_prefs.mail_type
    m
  end
  
  def user
    @user = Customer.find(logged_customer) if @user.nil?
    @user
  end
  
  def get_mail_prefs
    if not(@mailprefs)
      if not(@mailprefs = MailPref.find_by_customer(logged_customer))
        @mailprefs = MailPref.create("customer_id"=>logged_customer)
      end
    end  
    @mailprefs
  end
  
  def send_part(part)
    if part.content_type == "text/html"
      disposition = "inline"
    elsif part.content_type.include?("image/")
      disposition = "inline"          
    else  
      disposition = "attachment"
    end
    @headers['Content-Length'] = part.body.size
    @response.headers['Accept-Ranges'] = 'bytes'
    @headers['Content-type'] = part.content_type.strip
    @headers['Content-Disposition'] = disposition << %(; filename="#{part.header['content-type']['name']}")
    render_text part.body
  end
  
  def get_parts(mail)
    parts = Array.new
    parts << mail
    mail.parts.each { |part| 
      if part.multipart?
        parts = parts.concat(get_parts(part)) 
      elsif part.content_type and part.content_type.include?("rfc822")
      	parts = parts.concat(get_parts(TMail::Mail.parse(part.body))) << part
      else 
        parts << part
      end
    }  
    parts 
  end
  
  def obtain_cookies_for_search_and_nav
    @srch_class = ((cookies['_wmlms'] and cookies['_wmlms'] == 'closed') ? 'closed' : 'open')
    @srch_img_src = ((cookies['_wmlms'] and cookies['_wmlms'] == 'closed') ? 'closed' : 'opened') 
    @ops_class = ((cookies['_wmlmo'] and cookies['_wmlmo'] == 'closed') ? 'closed' : 'open')
    @ops_img_src = ((cookies['_wmlmo'] and cookies['_wmlmo'] == 'closed') ? 'closed' : 'opened')     
  end  
  
  ###################################################################
  ### Some fixed parameters and session variables
  ###################################################################
  def folder
  	@folders[@folder_name]
  end
  
  def msg_id_param
  	@params["msg_id"]
  end
  
  def messages_param
  	@params["messages"]
  end
  
  def dst_folder
  	@params["cpdest"]
  end
  
  def operation_param
  	@params["op"]
  end
end




