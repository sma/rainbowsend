# rules.rb - Rainbow's End is an empire building strategy PBEM game
# rules (C)2001 Russell Wallace, source code (C)2001 Stefan Matthias Aust

# Returns true if "h" belong to the area of any city.
def cityarea(h)
  nearestcity(h) < $cityseparation
end

# Prepares all units for this turn.
def refreshunits
  $units.each do |u|
    u.movement = Unittypes[u.type].movement
    u.special = 1
  end
end

# Returns true if player "p" has a unit with the specified "id".
def has(p, id) #private
  p.units.detect {|u| u.id == id}
end

# Assigns a valid id to unit "u".
def nextid(u)
  while has(u.player, u.id) do u.id += 1 end
end

Abbr = ["n", "ne", "se", "s", "sw", "nw"]
Full = ["north", "northeast", "southeast", "south", "southwest", "northwest"]

# Converts direction string "s" into direction number or -1 if "s" was invalid.
def finddir(s) #private
  Abbr.index(s.downcase) || Full.index(s.downcase) || -1
end

# Returns true if unit "u" destroys unit "u2". 
def destroys(u, u2, attack=u.attack) #private
  d = u2.defense
  if u2.hex!.units.detect {|uu| uu.city? && uu.player == u2.player}
    d += 2
  end
  rand(attack + d) < attack
end

# Performs the BUILD order. 
def build(u, args)
  p = u.player
  type = findunittype(args[0])
  if args[0].nil? && u.type == Unit::Settlers
    type = Unit::City
  end
  if type < 0
    u.event("Unit type not recognized")
    return
  end
  case u.type
    when Unit::City
      if type == Unit::City
        u.event("Cities can only be built by settlers")
        return
      end
    when Unit::Settlers
      if type != Unit::City
        u.event("Settlers can only build cities")
        return
      end
    else
      u.event("Only cities and settlers can build")
      return
  end
  if type == Unit::City && cityarea(u.hex!)
    u.event("Too close to an existing city")
		return
  end
  
  id = args[1].to_i
  if id < 1 || id > 99999 then id = 1 end

  if args[1] =~ /^[A-Za-z]/ && !args[2]
    args[2] = args[1]
  end

  name = args[2] || Unittypes[type].name

  cost = Unittypes[type].buildcost
  if cost == 0
    u.event("You cannot build this unit type")
    return
  end
  if p.money < cost
    u.event("Insufficient funds")
		return
  end
  
  p.money -= cost
  
  u2 = Unit.new(id, name, type, p, u.hex)
  nextid(u2)
  addunit(u2)
  
  if u.type == Unit::Settlers
    removeunit(u)
  end
  u.event("Built", u2.nameid)
	u2.event("Built in", u2.hex!.nameid)
	u2.hex!.event(u2.namepidtype, "built")
end

# Performs the DROP order.
def drop(u)
  removeunit(u)
  
  u.event("Dropped")
  u.hex!.event(u.namepidtype, "dropped")
end

# Performs the EMAIL order.
def email(p, args)
  email = args[0]
  if !email || email == ""
    p.event("New email address not given")
		return
  end
  
  p.email = email
  p.event("Email address changed to", email)
end

# Performs the FIRE order.
def fire(u, args)
  range = Unittypes[u.type].range
  if range == 0
    u.event("Not an indirect fire unit")
    return
  end
  if u.special == 0
    u.event("Already fired this turn")
    return
  end
  
  d = finddir(args[0] || '')
  if d >= 0
    hex = displace(u.hex!, d)
    if !hex
      u.event("Target hex is off the map")
      return
    end
  else
    hex = findhex(args[0] || '')
    if !hex
      u.event("Target hex not recognized")
      return
    end
  end
  if distance(u.hex!, hex) > range
    u.event("Target hex is out of range")
    return
  end
  
  hex.units.each do |u2|
    if u2.player == u.player || u.player.friendly.include?(u2.player)
      u.event("Friendly units in target area - fire mission aborted")
      return
    end
  end
  
  if hex.units.empty?
    u.event("No units in target area - fire mission aborted")
    return
  end

  u.special = 0
  
  u.event("Firing on", hex.nameid)
  hex.event("Incoming fire from", u.namepidtype, "in", u.hex!.nameid)

  hex.units.dup.each do |u2|
    if u2.type == Unit::City
      u.event(u2.namepidtype, "survived")
      u2.event("Incoming fire from", u.namepidtype, "in", u.hex!.nameid, "- survived")
      hex.event(u2.namepidtype, "survived")
      next
    end
    
    u2.player.friendly.remove u.player #sma

    if !destroys(u, u2, 2)
      u.event(u2.namepidtype, "survived")
      u2.event("Incoming fire from", u.namepidtype, "in", u.hex!.nameid, "- survived")
      hex.event(u2.namepidtype, "survived")
      next
    end
    
    u.event(u2.namepidtype, "destroyed")
    u2.event("Incoming fire from", u.namepidtype, "in", u.hex!.nameid, "- destroyed")
    hex.event(u2.namepidtype, "destroyed")
    
    removeunit(u2)
  end
end

# Performs the FRIENDLY order.
def friendly(p, args)
  p2 = findplayer(args[0].to_i)
  if !p2
    p.event("Player not recognized")
		return
  end
  
  if !p.friendly.include?(p2)
    p.friendly.add(p2)
  end
  
  p.event("Declared", p2.nameid, "as friendly")
end

# Performs the GIVE order.
def give(p, args)
	p2 = findplayer(args[0].to_i)
	if !p2
		p.event("Player not recognized")
		return
	end
	qty = min(max(args[1].to_i, 1), p.money)

  p.money -= qty
  p2.money += qty

	p.event("Gave", p2.nameid, qty, "money")
	p2.event(p.nameid, "gave", qty, "money")
end

# Performs the GROUP order.
def group(u, args)
end

# Performs the HOSTILE order.
def hostile(p, args)
  p2 = findplayer(args[0].to_i)
  if p2.nil?
    p.event("Player not recognized")
		return
  end
  
  p.friendly.remove(p2)
  
  p.event("Declared", p2.nameid, "as hostile")
end

# Performs the MOVE order.
def move(u, args)
  d = finddir(args[0] || '')
  if d >= 0
    hex = displace(u.hex!, d)
    if !hex
      u.event("Destination is off the map")
			return
    end
  else
    hex = findhex(args[0] || '')
    if !hex
      u.event("Destination not recognized")
			return
    end
  end
  if distance(u.hex!, hex) > 1
    u.event("Destination is not an adjacent hex")
		return
  end
  
  if hex.water?
    u.event("Destination is a water hex")
		return
  end
  
  cost = Terrains[hex.terrain].movementcost
  if u.movement < cost
    u.event("Not enough movement points left")
		return
  end
  
  from = u.hex!
  u.movement -= cost
  moveunit(u, hex)
  
  u.event("Moved from", from.nameid, "to", hex.nameid)
  from.event(u.namepidtype, "moved to", hex.idstr)
	hex.event(u.namepidtype, "arrived from", from.idstr)
end

# Performs the NAME order.
def name(e, args)
  name = args[0]
  if !name || name == ""
    e.event "New name not given"
    return
  end

  e.name = name
  e.event "Name changed to", name
end

# Performs the QUIT order.
def quit(p)
  p.email = nil
end

# Performs the UNGROUP order.
def ungroup(u, args)
end

# Returns true if unit "u" could attack unit "u2".
def cantarget(u, u2) #private
  !(u2.city? || u2.ruin? || u.player == u2.player || 
    u.player.friendly.include?(u2.player))
end

# Returns a randomly choosen opponent for unit "u" or nil if there's none.
def findtarget(u) #private
  return nil if u.attack == 0
  
  targets = u.hex!.units.select{|u2| cantarget(u, u2)}
  return nil if targets.empty?
  
  targets[rand(targets.length)]
end

# Handle all combat on hex "h".
def combathex(h) #private
  h.units.shuffle.each do |u|
    next if u.removed
    u2 = findtarget(u)
    next unless u2
    
    u2.player.friendly.remove u.player #sma
    if !destroys(u, u2)
      u.event "Attacking", u2.namepidtype, "without effect"
      u2.event "Attacked by", u.namepidtype, "without effect"
      h.event u.namepidtype, "attacks", u2.namepidtype, "without effect"
    else
      u.event "Attacking and destroying", u2.namepidtype
      u2.event "Destroyed by", u.namepidtype
      h.event u.namepidtype, "attacks and destroys", u2.namepidtype
      removeunit(u2)
    end
  end
end

# Handle all combat for one phase.
def combat()
  $hexes.each do |h|
    combathex(h) unless h.units.empty?
  end
end

# Handle capture of unit "c" in hex "h".
def captureunit(c, h) #private
  h.units.shuffle.each do |u|
    next if u.attack == 0
    next if u.player == c.player
    next if u.player.friendly.include? c.player

    next if h.units.detect {|u2|
      cantarget(u, u2) || (u2.attack > 0 && cantarget(u2, u2))
    }
    c2 = Unit.new(1, c.name, c.type, u.player, h.h)
    nextid(c2)
    addunit(c2)
   
    u.event "Captured", c.namepid
    c.event "Captured by", u.namepid
    c2.event "Captured by", u.namepid
    h.event u.namepidtype, "captured", c.namepid, "- now designated", c2.pid
    
    c2.event "Send settlers to EXPLORE the ruins" if c2.ruin?
    
    removeunit(c)
    break
  end
end

# Handle capture of units in hex "h".
def capturehex(h) #private
  c = h.units.detect {|u| u.city?}
  captureunit(c, h) if c
end

# Handle all capture for one phase.
def capture()
  $hexes.each do |h|
    capturehex(h) unless h.units.empty?
  end
end

# Increase player's money by adding unit-generated income. 
def income()
  $units.each do |u|
    income = -Unittypes[u.type].upkeepcost
    u.player.money += income if income > 0
  end
end

# Upkeep all units, remove unsupported units.
def upkeep()
  $players.each do |p|
    p.units.dup.each do |u|
      upkeep = Unittypes[u.type].upkeepcost
      next if upkeep < 0
      if p.money >= upkeep
        p.money -= upkeep
      else
        removeunit(u)
      end
    end
  end
end

