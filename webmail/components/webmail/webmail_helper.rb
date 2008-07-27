require 'cdfutils'
require 'mail2screen'

module Webmail::WebmailHelper
  include Mail2Screen
  def link_folders
    link_to(_('Folders'), :controller=>"/webmail/webmail", :action=>"messages")
  end
  
  def link_send_mail
    link_to(_('Compose'), :controller=>"/webmail/webmail", :action=>"compose")
  end

  def link_compose_new
    link_to(_('Compose new mail'), :controller=>"/webmail/webmail", :action=>"compose")
  end
  
  def link_refresh
    link_to(_('Refresh'), :controller=>"/webmail/webmail", :action=>"refresh")
  end
  
  def link_message_list
    link_to(_('Message list'), :controller=>"/webmail/webmail", :action=>"messages")
  end
  
  def link_reply_to_sender(msg_id)
    link_to(_('Reply'), :controller=>"/webmail/webmail", :action=>"reply", :params=>{"msg_id"=>msg_id})
  end
  
  def link_forward_message(msg_id)
    link_to(_('Forward'), :controller=>"/webmail/webmail", :action=>"forward", :params=>{"msg_id"=>msg_id})
  end
  
  def link_flag_for_deletion(msg_id)
    link_to(_('Delete'), :controller=>"/webmail/webmail", :action=>"delete", :params=>{"msg_id"=>msg_id})
  end
  
  def link_view_source(msg_id)
    link_to(_('View source'), {:controller=>"/webmail/webmail", :action=>"view_source", :params=>{"msg_id"=>msg_id}}, {'target'=>"_blank"})
  end
  
  def link_manage_folders
    link_to(_('add/edit'), :controller=>"/webmail/webmail", :action=>"manage_folders")
  end

  def link_back_to_messages
    link_to("&#171;" << _('Back to messages'), :controller=>"/webmail/webmail", :action=>"messages")
  end
  
  def link_mail_prefs
    link_to(_('Preferences'), :controller=>"/webmail/webmail", :action=>"prefs")
  end
  
  def link_mail_filters
    link_to(_('Filters'), :controller=>"/webmail/webmail", :action=>"filters")
  end

  def link_filter_add
    link_to(_('Add filter'), :controller=>'/webmail/webmail', :action=>'filter_add')
  end
  
  def folder_link(folder)
  	if folder.attribs.include? :Noselect
      return folder.name
    end
    if folder.unseen > 0
      fn = "#{short_fn(folder)} (#{folder.unseen})"
    else
      fn = "#{short_fn(folder)}"
    end      
    if folder.name == CDF::CONFIG[:mail_trash]
      (folder.unseen > 0 ? "<b>" : "" ) <<
        link_to( fn, :controller=>"/webmail/webmail", :action=>"messages", :params=>{"folder_name"=>folder.name}) << 
          "&nbsp;" << link_to(_('(Empty)'), {:controller=>"/webmail/webmail", :action=>"empty", :params=>{"folder_name"=>folder.name}}, :confirm => _('Do you really want to empty trash?')) <<
      (folder.unseen > 0 ? "</b>" : "" )
    else
      (folder.unseen > 0 ? "<b>" : "" ) <<
      link_to( fn, :controller=>"/webmail/webmail", :action=>"messages", :params=>{"folder_name"=>folder.name}) <<
      (folder.unseen > 0 ? "</b>" : "" )
    end  
  end
  
  def short_fn(folder)
    if folder.name.include? folder.delim
      "&nbsp; &nbsp;" + folder.name.split(folder.delim).last
    else
      folder.name
    end
  end
  
  def folder_manage_link(folder)
    if folder.name == CDF::CONFIG[:mail_trash] or folder.name == CDF::CONFIG[:mail_inbox] or folder.name == CDF::CONFIG[:mail_sent]
      short_fn(folder)
    else
      return short_fn(folder) +
      ("&nbsp;" + link_to(_('(Delete)'), :controller=>"/webmail/webmail", :action=>"manage_folders", :params=>{"op"=>_('(Delete)'), "folder_name"=>folder.name}))
    end  
  end
  
  def message_date(datestr)
    t = Time.now
    begin
    	if datestr.kind_of?(String)
	      d = (Time.rfc2822(datestr) rescue Time.parse(value)).localtime
	    else
	    	d = datestr
	    end
      if d.day == t.day and d.month == t.month and d.year == t.year
        d.strftime("%H:%M")
      else
        d.strftime("%Y-%m-%d")
      end  
    rescue
      begin
        d = imap2time(datestr)
        if d.day == t.day and d.month == t.month and d.year == t.year
          d.strftime("%H:%M")
        else
          d.strftime("%Y-%m-%d")
        end  
      rescue
        datestr
      end
    end
  end
  
  def attachment(att, index)
    ret = "#{att.filename}"
    # todo: add link to delete attachment
    #ret << 
    ret << "<input type='hidden' name='att_files[#{index}]' value='#{att.filename}'/>"
    ret << "<input type='hidden' name='att_tfiles[#{index}]' value='#{att.temp_filename}'/>"
    ret << "<input type='hidden' name='att_ctypes[#{index}]' value='#{att.content_type}'/>"
  end
  
  def link_filter_up(filter_id)
    link_to(_('Up'), :controller=>"/webmail/webmail", :action=>"filter_up", :id=>filter_id)
  end
  
  def link_filter_down(filter_id)
    link_to(_('Down'), :controller=>"/webmail/webmail", :action=>"filter_down", :id=>filter_id)
  end
  
  def link_filter_edit(filter_id)
    link_to(_('Edit'), :controller=>"/webmail/webmail", :action=>"filter", :id=>filter_id)
  end
  
  def link_filter_delete(filter_id)
    link_to(_('Delete'), :controller=>"/webmail/webmail", :action=>"filter_delete", :id=>filter_id)
  end
  
  def page_navigation_webmail(pages)
    nav = "<p class='paginator'><small>"
    
    nav << "(#{pages.length} #{_('Pages')}) &nbsp; "
    
    window_pages = pages.current.window.pages
    nav << "..." unless window_pages[0].first?
    for page in window_pages
      if pages.current == page
        nav << page.number.to_s << " "
      else
        nav << link_to(page.number, :controller=>"/webmail/webmail", :action=>'messages', :page=>page.number) << " "
      end
    end
    nav << "..." unless window_pages[-1].last?
    nav << " &nbsp; "
    
    nav << link_to(_('First'), :controller=>"/webmail/webmail", :action=>'messages', :page=>@pages.first.number) << " | " unless @pages.current.first?
    nav << link_to(_('Prev'), :controller=>"/webmail/webmail", :action=>'messages', :page=>@pages.current.previous.number) << " | " if @pages.current.previous
    nav << link_to(_('Next'), :controller=>"/webmail/webmail", :action=>'messages', :page=>@pages.current.next.number) << " | " if @pages.current.next
    nav << link_to(_('Last'), :controller=>"/webmail/webmail", :action=>'messages', :page=>@pages.last.number) << " | " unless @pages.current.last?
    
    nav << "</small></p>"
    
    return nav
  end

  def parse_subject(subject)
    begin
      if mime_encoded?(subject)
        if mime_decode(subject) == '' 
          _('(No subject)')
        else
          mime_decode(subject)
        end
      else
        if from_qp(subject) == ''  
          _('(No subject)')
        else
          from_qp(subject)
        end
      end
    rescue Exception => ex
      RAILS_DEFAULT_LOGGER.debug('Exception occured - #{ex}')
      return ""
    end         
  end
  
  def message_size(size) 
  	if size / (1024*1024) > 0
  		return "#{(size / (1024*1024)).round}&nbsp;MB"
  	elsif size / 1024 > 0	
  		return "#{(size / (1024)).round}&nbsp;KB"
  	else
  		return "#{size}&nbsp;B"
  	end	
  end
end

