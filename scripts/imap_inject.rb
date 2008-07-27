#!/usr/bin/ruby

require 'net/imap'

imap = Net::IMAP.new('localhost')
imap.authenticate('LOGIN', 'vpuz@rogers.com', 'secret')

imap.append("inbox", $stdin.read.gsub(/\n/, "\r\n") )
