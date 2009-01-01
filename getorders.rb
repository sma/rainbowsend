#!/usr/bin/env ruby -w
# getorders.rb - Rainbow's End is an empire building strategy PBEM game
# rules (C)2001 Russell Wallace, source code (C)2001 Stefan Matthias Aust

require 'net/pop'

$popserver = 'pop3.XXXXXXXXX'
$popuser = 'orders@XXXXXXXXX'
$poppassword = 'XXXXXXXXX'

# contact ISP

pop = Net::POP3.new($popserver)
pop.start($popuser, $poppassword)

$stderr.print "Found #{pop.mails.length} messages in mailbox.\n"
pop.each do |m|
  $stderr.puts m.header.split("\r\n").grep(/^From: /)
  m.all($stdout)
end
if ARGV[0] == '--delete'
  $stderr.print "Deleting all pending messages..."
  pop.each do |m| m.delete! end
  $stderr.print "done\n"
end

pop.finish

