# player.rb - Rainbow's End is an empire building strategy PBEM game
# rules (C)2001 Russell Wallace, source code (C)2001 Stefan Matthias Aust

class Player < Entity
  attr_accessor :email, :money, :lastorders, :friendly, :units, :removedunits
  def initialize
    super()
    @friendly = []
    @units = []
    @removedunits = []
  end
  
  def <=>(p)
    if (cmp = p.units.length <=> units.length) == 0
      if (cmp = p.money <=> money) == 0
        cmp = id <=> p.id
      end
    end
    cmp
  end
  
  def cansee(o)
    h = (o.is_a? Unit) ? o.hex! : o
    @units.detect {|u| distance(u.hex!, h) < $sightingdistance}
  end
end

$players = []

def countplayers #private
  file = File.open("players")
  file || raise("Players file not found")
  begin
    $humanplayers = 0
    file.each do |line|
      next if parse(line).empty?
      $humanplayers += 1
    end
  ensure
    file.close
  end
end

def readplayers #private
  file = File.open("players")
  file || raise("Unable to open players file")
  begin
    $players.each_with_index do |p, i|
      if i < $humanplayers
        begin
          words = parse(file.gets)
        end while words.empty?
        p.name = "Player"
        p.email = words[0]
      else
        p.name = "Computer"
        p.email = nil
      end
      p.id = i + 1  
      p.money = $startingmoney
      p.lastorders = 0
    end
  ensure
    file.close
  end
end

def initplayers
  countplayers
  allocplayers
  readplayers
end

def allocplayers
  $players = (0...($humanplayers + $computerplayers)).map {Player.new}
end

def findplayer(id)
  $players.detect {|p| p.id == id}
end

def removeplayers
  $players = $players.select do |p|
    if p.units.length > 0
      true
    else
      $players.each {|pp| pp.friendly.remove(p)}
      false
    end
  end
end

