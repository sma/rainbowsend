# save.rb - Rainbow's End is an empire building strategy PBEM game
# rules (C)2001 Russell Wallace, source code (C)2001 Stefan Matthias Aust

module Save

@file = nil

private

def Save.write_s(s)
  @file.print "\"#{s}\""
end

def Save.write_n(n)
  @file.print "#{n}"
end

def Save.space(n = 1)
  @file.print " " * n
end

def Save.newline() 
  @file.print "\n"
end

def Save.comment(c)
  @file.print "\# #{c}\n"
end

def Save.write(n, c)
  write_n n
  space 2
  comment c
end

public

def Save.save
  @file = File.open("game", "w")
  @file || raise("Unable to create save game file")
  begin
    
  write $turn, "turn"
  
  write $players.length, "players"
  
  comment "number, name, email, money, last orders"
  $players.each do |p|
    write_n p.id
    space
    write_s p.name
    space
    write_s p.email
    space
    write_n p.money
    space
    write_n p.lastorders
    newline
  end
  newline
  
  write "#{$mapsizex} #{$mapsizey}", "map size"
  
  comment "terrain"
  $hexes.each do |h|
    write_n h.terrain
    newline
  end
  newline
  
  write $units.length, "units"

  comment "number, name, type, player, hex"
  $units.each do |u|
    write_n u.id
    space
    write_s u.name
    space
    write_n u.type
    space
    write_n u.player.id
    space
    write_n u.hex
    newline
  end
  newline
  
  n = 0
  $players.each do |p| n += p.friendly.length end
  
  write n, "friendly"

  comment "player, other"
  $players.each do |p|
    p.friendly.each do |p2|
      write_n p.id
      space
      write_n p2.id
      newline
    end
  end
  ensure
    @file.close
  end
end

private

def Save.read
  begin
    line = @file.gets
    return nil if line.nil?
    words = parse(line)
  end while words.empty?
  words
end

public

def Save.load
  @file = File.open("game", "r")
  @file || raise("Save game file not found")
  begin
    words = read
    $turn = words[0].to_i
    
    words = read
    $players = (0...(words[0].to_i)).map{Player.new}
    
    $players.each do |p|
      words = read
      p.id = words[0].to_i
      p.name = words[1]
      p.email = words[2]
      if p.email == "" then p.email = nil end
      p.money = words[3].to_i
      p.lastorders = words[4].to_i
    end
    
    words = read
    $mapsizex = words[0].to_i
    $mapsizey = words[1].to_i
    allochexes
    
    $hexes.each do |h|
      words = read
      h.terrain = words[0].to_i
    end
    
    words = read
    words[0].to_i.times do
      words = read
      addunit(Unit.new(
        words[0].to_i, words[1], words[2].to_i,
        findplayer(words[3].to_i), words[4].to_i))
    end
    
    words = read
    words[0].to_i.times do
      words = read
      p = findplayer(words[0].to_i)
      p2 = findplayer(words[1].to_i)
      p.friendly.add(p2)
    end
  ensure
    @file.close
  end
end

end
