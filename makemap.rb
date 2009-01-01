#!/usr/bin/env ruby -w
# makemap.rb - Rainbow's End is an empire building strategy PBEM game
# rules (C)2001 Russell Wallace, source code (C)2001 Stefan Matthias Aust

class Integer
  def odd() (self & 1) != 0 end
end

class Hex
  attr_reader :x, :y, :city
  attr_writer :city
  def initialize(x,y,terrain,city)
    @x, @y, @terrain, @city = x.to_i, y.to_i, terrain, city
  end
  def terrain
    case @terrain
    when "forest";  "woods"
    when "mountain"; "mnts."
    else @terrain
    end
  end
end

  def Hex.find(x, y)
    $hexes.detect {|each| each.x == x && each.y == y}
  end  

$hexes = []

while gets
  $mapsizex, $mapsizey = $1.to_i, $2.to_i if /Map size:\s+(\d+)x(\d+)/
  next unless /^Hex summary/
  gets
  gets
  while gets
    break if /--/
    $hexes << Hex.new(*split)
  end
  while gets
    next unless /^unit (\d+).*City in.*\[(\d+)\/(\d+)\]/
    if hex = Hex.find($2.to_i, $3.to_i) then hex.city = "C%04d" % $1.to_i end
  end
  break
end

for x in 0...$mapsizex
  print(x.odd ? "       " : "  _____")
end #for x
print "\r\n"

for y in 0...$mapsizey
  for i in 0..3
    for x in 0...$mapsizex
      hex = Hex.find(x, y)
      case x.odd ? (i+2)%4 : i
      when 0; print " /%2d/%2d" % [x, y]
      when 1; print hex ? "/ %5s" % hex.terrain : "/      "
      when 2; print "\\      "
      when 3; print " \\_____"
      end
    end #for x
    case x.odd ? (i+2)%4 : i
    when 0; print "\\ \r\n"
    when 1; print " \\\r\n"
    when 2; print " /\r\n"
    when 3; print "/ \r\n"
    end
  end #for i
end #for y

for x in 0...$mapsizex
  print(x.odd ? "\\      " : " /     ")
end
print($mapsizex.odd ? "\\ \r\n" : "  \r\n")

for x in 0...$mapsizex
  print(x.odd ? " \\_____" : "/      ")
end
print($mapsizex.odd ? " \\\r\n" : "  \r\n")

