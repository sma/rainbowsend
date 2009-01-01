# unit.rb - Rainbow's End is an empire building strategy PBEM game
# rules (C)2001 Russell Wallace, source code (C)2001 Stefan Matthias Aust

class Unittype
  attr_reader :name, :buildcost, :upkeepcost
  attr_reader :movement, :attack, :defense, :range
  
  def initialize(name, buildcost, upkeepcost, movement, attack, defense, range) 
    @name = name
    @buildcost = buildcost
    @upkeepcost = upkeepcost
    @movement = movement
    @attack = attack
    @defense = defense
    @range = range
  end
end

class Unit < Entity
  City = 0
  Settlers = 1
  Infantry = 2
  Tanks = 3
  Artillery = 4
  
  attr_accessor :type, :player, :hex, :movement, :special, :removed
  
  def initialize(id, name, type, player, hex) 
    super()
    @id, @name, @type, @player, @hex = id, name, type, player, hex
    @removed = false
    @special = 0
  end
  
  def city?
    type == City
  end
  
  def hex!
    $hexes[hex]
  end

  def pid
    "[#{@player.id}-#{@id}]"
  end  

  def namepid
    "#{@name} #{pid}"
  end

  def namepidtype
    "#{namepid} (#{Unittypes[@type].name})"
  end
  
  def attack
    Unittypes[type].attack
  end
  
  def defense
    Unittypes[type].defense
  end
end

Unittypes = [
  Unittype.new("city", 20, -10, 0, 0, 0, 0),
  Unittype.new("settlers", 10, 1, 3, 0, 2, 0),
  Unittype.new("infantry", 10, 1, 3, 4, 4, 0),
  Unittype.new("tanks", 20, 2, 6, 8, 6, 0),
  Unittype.new("artillery", 20, 2, 3, 2, 4, 2),
]

$units = []

def deletecities #private
  $units.each do |u|
    u.player.units.clear
    u.hex!.units.clear
  end
  $units.clear
end

def initcities #private
  
  # Create one city per player
  
  $players.each do |p|
    c = Unit.new(1, "City", Unit::City, p, -1)
    begin
      c.hex = rand($hexes.length)
    end while $hexes[c.hex].water?
    addunit(c)
  end
  
  # Separate them as far as possible
  
  more = true
  while more
    more = false
    $units.each do |c|
      r = nearestcity(c.hex!, c)
      a = Array.new(6)
      j = 0
      for d in 0..5
        hex = displace(c.hex!, d)
        next if !hex || hex.water?
        if nearestcity(hex, c) > r
          a[j] = hex
          j += 1
        end
      end
      next if j == 0

      moveunit(c, a[rand(j)])
      more = true
    end
  end

  # Check if they're now adequately separated
  
  !$units.find {|c| nearestcity(c.hex!, c) < $cityseparation + 1}
end

def initunits
  10.times do
    return if initcities
    deletecities
  end
  raise("Unable to place starting cities")
end

def addunit(u)
  $units.add(u)
  u.hex!.units.add(u)
  
  units = u.player.units
  if units.empty? || units[-1].id < u.id
    units.add(u)
  else
    i = 0
    while i < units.length && units[i].id > u.id
      i += 1
    end
    units[i,0] = u
  end
end

def findunittype(s)
  return -1 if !s
  ut = Unittypes.detect{|ut| s.downcase == ut.name[0, s.length]}
  Unittypes.index(ut) || -1
end

def findunit(p, id)
  p.units.detect{|u| u.id == id}
end

def nearestcity(h, c = nil)
  r = 999999
  $units.each do |c2|
    if c2 != c && c2.city?
      r = min(r, distance(h, c2.hex!))
    end
  end
  r
end

def moveunit(u, hex)
  u.hex!.units.remove(u)
  u.hex = hex.h
  u.hex!.units.add(u)
end

def removeunit(u)
  $units.remove(u)
  u.player.units.remove(u)
  u.player.removedunits.add(u)
  u.hex!.units.remove(u)
  u.removed = true
end

