# ai.rb - Rainbow's End is an empire building strategy PBEM game
# rules (C)2001 Russell Wallace, source code (C)2001 Stefan Matthias Aust

$moneythreshold = Unittypes.collect{|ut| ut.buildcost}.max

def decideorders_(p) #private
  p.units.each do |u|
    if u.city?
      if p.money >= $moneythreshold
        ut = Unittypes[
          case rand(3)
          when 0; Unit::Tanks
          when 1; Unit::Artillery
          when 2; Unit::Infantry
          end]
        u.orders.add(Order.new(Order::Build, [ut.name]))
      elsif rand(3) > 0
        ut = Unittypes[Unit::Infantry]
        u.orders.add(Order.new(Order::Build, [ut.name]))
      end
    else
      combatorders(u)
    end
  end
end

def combatorders(u) #private
  targets = $units.select {|u2| distance(u.hex!, u2.hex!) < $sightingdistance}
  if Unittypes[u.type].range > 0 then
    targets.map {|u2| u2.hex!}.shuffle.each do |h|
      u.orders.add(Order.new(Order::Fire, ["#{h.x}/#{h.y}"])) if h != u.hex!
    end
    $stderr.print u.orders.inspect
  end
end

def decideorders
  $players.each do |p|
    if !p.email || p.lastorders < $turn - 1 then decideorders_(p) end
  end
end

