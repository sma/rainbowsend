# writerpt.rb - Rainbow's End is an empire building strategy PBEM game
# rules (C)2001 Russell Wallace, source code (C)2001 Stefan Matthias Aust

module Report

@file = nil

private

def Report.write(s, width = nil)
  s = s.to_s
  @file.print s
  width && space(width - s.length)
end

def Report.write_c(n, c)
  n > 0 && @file.print(c * n)
end

def Report.space(n)
  write_c(n, ' ')
end

def Report.newline
  @file.print "\n"
end

def Report.right(s, width)
  s = s.to_s
  space(width - s.length)
  write(s)
end

def Report.wrap(s, indent)
  i = indent
  j = 0
  while j < s.length
    k = j
    # find next word break
    while j < s.length && s[j] != ' ' do j += 1 end
    
    if i > indent && i + 1 + j > 70
      newline
      space indent
      i = indent
    end
    
    if i > indent
      space 1
      i += 1
    end
    
    i += j
    write s[k..j]
    j += 1
  end
end

def Report.writeline(s)
  write s
  newline
end

def Report.underline(s)
  writeline s
  write_c s.length, '-'
  newline
  newline
end

def Report.item(caption, width, s)
  s = s.to_s
  space 2
  write caption
  write ":"
  space(width + 2 - caption.length)
  writeline s
end

def Report.countcities(units)
  units.select{|u| u.city?}.length
end

def Report.reportevent(s)
  space 2
  i = s.index(' ') 
  write s[0, i]
  wrap((s[i + 1..-1]||""), i + 3)
  newline
end

def Report.reportevents(e)
  e.events.each {|ev| reportevent(ev)}
  newline unless e.events.empty?
end

def Report.reportmsg()
  msgfile = File.open("message", "r")
  if msgfile
    while line = msgfile.gets
      @file.print line
    end
    msgfile.close
  end
end

def Report.reportheader(p)
  write "Rainbow's End Turn #{$turn}\n#{p.nameid}\n\n"
end

def Report.reporttotals
  money = 0
  $players.each {|p| money += p.money}
  cities = countcities($units)
  
  writeline "Game totals"
  item "Players", 11, $players.length
  item "Map size", 11, "#{$mapsizex}x#{$mapsizey}"
  item "Money", 11, money
  item "Cities", 11, cities
  item "Other units", 11, ($units.length - cities)
  newline
end

def Report.reportgeneralorders(p)
  return if p.events.length == 0
  writeline "General orders"
  reportevents(p)
end

def Report.reportplayersummary(p)
  writeline "Player summary"
	writeline "  number  relations  money  units"
	writeline "  ------  ---------  -----  -----"
  
  totmoney = 0
  totunits = 0
  
  $players.sort.each do |p2|
    space 2
    write p2.id, 8
    if p == p2
      write "n/a", 9
    elsif p.friendly.include? p2
      write "friendly", 9
    else
      write "hostile", 9
    end
    right p2.money, 7
    right p2.units.length, 7
    newline
    
    totmoney += p2.money
    totunits += p2.units.length
  end
  
  writeline "  ------  ---------  -----  -----"
  writeline "                     %5d  %5d" % [totmoney, totunits]

	newline
end

def Report.reportplayerdetails(p)
  underline "Player details"
  
  $players.each do |p2|
    cities = countcities(p2.units)
    
    writeline p2.nameid
    item "Email", 11, (p2.email || "None")
    if p == p2
      item "Relations", 11, "n/a"
    elsif p.friendly.include? p2
      item "Relations", 11, "friendly"
    else
      item "Relations", 11, "hostile"
    end
    item "Money", 11, p2.money
    item "Cities", 11, cities
    item "Other units", 11, (p2.units.length - cities)
    newline
  end
end

def Report.reportunitsummary(p, p2)
  found = false
  p2.units.each do |u|
    if p.cansee(u)
      found = true
      break
    end
  end
  return if not found
  
  writeline "Unit summary: %s" % p2.nameid
  writeline "  number  type        x   y  group"
	writeline "  ------  ---------  --  --  -----"
  
  p2.units.each do |u|
    next unless p.cansee(u)
    writeline "  %6d  %-9s%4d%4d  none" %
      [u.id, Unittypes[u.type].name, htox(u.hex), htoy(u.hex)]     
  end
  
  writeline "  ------  ---------  --  --  -----"
	newline
end

def Report.reportunitdetails(p)
  underline("Unit details")
  
  i = j = 0
  while i < p.units.length || j < p.removedunits.length
    ui = nil
    if i < p.units.length
      ui = p.units[i]
    end
    uj = nil
    if j < p.removedunits.length
      uj = p.removedunits[j]
    end
    u = nil
    if ui == nil
      u = uj
      j += 1
    elsif uj == nil
      u = ui
      i += 1
    elsif ui.id < uj.id
      u = ui
      i += 1
    else
      u = uj
      j += 1
    end
    
    writeline(u.nameid)
    reportevents(u)
    
    next if u.removed
    
    item "Type", 12, Unittypes[u.type].name
    item "Location", 12, u.hex!.nameid
    item "Grouped with", 12, "None"
    newline
  end
end

def Report.reporthexsummary(p)
  return if p.units.empty?
  
  writeline "Hex summary"
	writeline "   x   y  terrain   city"
	writeline "  --  --  --------  ----"
  
  for y in 0...$mapsizey
    for x in 0...$mapsizex
      h = $hexes[xytoh(x, y)]
      next unless p.cansee(h)

      write "%4d%4d  %-8s   " % [x, y, Terrains[h.terrain].name] 
      writeline h.water? ? "n/a" : (cityarea(h) ? "yes" : "no")
    end
  end
  
  writeline "  --  --  --------  ----"
  newline
end

def Report.reporthexdetailshex(p, h)
  found = false
  h.events.each do |he|
    if he.players.include? p
      found = true
      break
    end
  end
  
  if p.cansee(h)
    $units.each do |u|
      if u.hex == h.h
        found = true
        break
      end
    end
  end
  
  return unless found
  
  writeline h.nameid
  
  found = false
  h.events.each do |he|
    if he.players.include? p
      reportevent(he.event)
      found = true
    end
  end
  newline if found
  
  return unless p.cansee(h)
  
  found = false
  $orig_players.each do |p2| #sma
    p2.units.each do |u|
      if u.hex! == h
        space 2
        write(p2 == p ? "* " : "- ")
        writeline u.namepidtype
        found = true
      end
    end
  end
  newline if found
  
  s = h.water? ? "n/a" : (cityarea(h) ? "Yes" : "No")
  item "City area", 9, s
  newline
end

def Report.reporthexdetails(p)
  underline "Hex details"
  
  $hexes.each do |h|
    reporthexdetailshex(p, h)
  end
end

def Report.templateitem(caption, n, co)
  write "#{caption} #{n}  \# #{co}\n\n"
end

def Report.reporttemplate(p)
  return if p.units.length == 0
  
  underline "Order template"
  
  templateitem "player", p.id, p.name
  p.units.sort{|a,b| a.hex <=> b.hex}.each do |u|
    templateitem "unit", u.id, "#{u.name} in #{u.hex!.nameid}"
  end
  writeline "end"
end

def Report.report(p)
  @file = File.open("#{p.id}.r", "w")
  @file || raise("Unable to create report file")
  $orig_players = $players.dup #sma
  lastplayer = $players.pop #sma
  begin
    reportmsg
    reportheader(p)
    reporttotals
    reportgeneralorders(p)
    reportplayersummary(p)
    reportplayerdetails(p)
    $orig_players.each {|p2| reportunitsummary(p, p2)}
    reportunitdetails(p)
    reporthexsummary(p)
    reporthexdetails(p)
    reporttemplate(p)
    if p.units.empty?
      write \
        "Unfortunately your empire has been eliminated from the game.\n"+
        "Hope you enjoyed playing; condolences on your ill fortune,\n"+
        "and better luck next time.\n"
    end
  ensure
    $players << lastplayer #sma
    $orig_players = nil #sma
    @file.close
  end
end

def Report.send
  @file = File.open("send.txt", "w")
  @file || raise("Unable to create send file")
  begin
    @file.print "$turn = #{$turn}\n"
    @file.print "$reports = {\n"
    $players.each do |p|
      next unless p.email
      @file.print "  '#{p.id}.r' => '#{p.email}',\n"
    end
    @file.print "}\n"
  ensure
    @file.close
  end
end

public

def Report.writereports
  $players.each {|p| report(p)}
  send
end

end

