# map.rb - Rainbow's End is an empire building strategy PBEM game
# rules (C)2001 Russell Wallace, source code (C)2001 Stefan Matthias Aust

class Terrain
  Terraintypes = [
    "water",
    "plain",
    "forest",
    "mountain",
  ]
  # create terrain constants via meta-magic
  Terraintypes.each_with_index {|t, i| const_set t.capitalize, i}
  
  attr_reader :name, :movementcost
  
  def initialize(name, movementcost)
    @name, @movementcost = Terraintypes[name], movementcost
  end
end

class Hexevent
  attr_reader :event, :players
  def initialize(event)
    @event = event
    @players = []
  end
end

class Hex
  attr_accessor :terrain
  attr_reader :h, :units, :events
  
  def initialize(h)
    @h = h
    @terrain = Terrain::Water
    @units = []
    @events = []
  end
  
  def water?
    @terrain == Terrain::Water
  end
  
  def x
    h % $mapsizex
  end
  
  def y
    h / $mapsizex
  end
  
  def idstr
    "[#{x}/#{y}]"
  end

  def nameid
    "#{Terrains[terrain].name} #{idstr}"
  end
    
  def event(*s) 
    he = Hexevent.new("#{$slot}: #{s.join(' ')}.")
    $players.each do |p|
      if p.cansee(self) then he.players.add(p) end
    end
    @events.add(he)
  end
end

Terrains = [
  Terrain.new(Terrain::Water, 0),
  Terrain.new(Terrain::Plain, 1),
  Terrain.new(Terrain::Forest, 2),
  Terrain.new(Terrain::Mountain, 3),
]

$hexes = []

def allochexes
  $hexes = (0...($mapsizex * $mapsizey)).map {|h| Hex.new(h)} 
end

def offshore(h) #private
  if h.water?
    for d in 0..5
      h2 = displace(h, d)
      return true if h2 && !h2.water?
    end
  end
  false
end

def inithexes
  allochexes

  count = $hexes.length
  $hexes[rand(count / 2) + count / 4].terrain = Terrain::Mountain
  
  for i in 0...(count / 2 - 1)
    a = []
    $hexes.each do |h|
      if offshore(h) then a << h end
    end
    h = a[rand(a.length)]
    h.terrain = 
      case rand(4)
        when 0; Terrain::Mountain
        when 1; Terrain::Forest
        else Terrain::Plain
      end
  end
end 

def findterrain(s)
  terrain = Terrain::Terraintypes.detect {|each| s == each[0, s.length]}
  Terrain::Terraintypes.index(terrain) || -1
end

def findhex(s)
  x, y = s.split('/')
  x = x.to_i
  y = y.to_i
  if onmap(x, y)
    $hexes[xytoh(x, y)]
  else
    nil
  end
end

def onmap(x, y)
  x >= 0 && x < $mapsizex && y >= 0 && y < $mapsizey
end

def xytoh(x, y)
  y * $mapsizex + x
end

def htox(h)
  h % $mapsizex
end

def htoy(h)
  h / $mapsizex
end

def displace(hex, d)
  x, y = hex.x, hex.y
  
  case d
  when 0
    y -= 1
  when 1
    y -= 1 if x.even
    x += 1
  when 2
    y += 1 if x.odd
    x += 1
  when 3
    y += 1
  when 4
    y += 1 if x.odd
    x -= 1
  when 5
    y -= 1 if x.even
    x -= 1
  end

  if onmap(x, y)
    $hexes[xytoh(x, y)]
  else
    nil
  end
end

def htoa(h) #private
  (h.x + 1) / 2 + h.y
end

def htob(h) #private
  h.x / 2 - h.y
end
  
def distance(h1, h2)
  a1, b1 = htoa(h1), htob(h1)

  a2, b2 = htoa(h2), htob(h2)

  da = a1 - a2
  db = b1 - b2

  sign = da.sign == db.sign
  
  da = da.abs
  db = db.abs
  
  if sign
    da + db
  else
    max(da, db)
  end
end

