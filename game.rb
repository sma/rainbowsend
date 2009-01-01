# game.rb - Rainbow's End is an empire building strategy PBEM game
# rules (C)2001 Russell Wallace, source code (C)2001 Stefan Matthias Aust

$turn = 0
$slot = 0
    
def newgame
  $turn = 0
  initplayers
  inithexes
  initunits
  Report.writereports
  Save.save
end

def playerorders #private
  for $slot in 1..Maxorders do
    si = $slot - 1
    $players.each do |p|
      if si < p.orders.length
        doorder(p, p.orders[si])
      end
    end
  end
end

def unitorders_(phase) #private
  si = $slot - 1
  $units.shuffle.each do |u|
    next if u.removed || si >= u.orders.length
    o = u.orders[si]
    case o.type
    when Order::Build, Order::Drop
      next if phase != 2
    when Order::Move
      next if phase != 1
    else
      next if phase != 0
    end
    doorder(u, o)
  end
end

def unitorders #private
  for $slot in 1..Maxorders do
    unitorders_(0)
    unitorders_(1)
    combat
    capture
    unitorders_(2)
  end
end

def runturn
  $slot = 0
  Save.load
  readorders
  decideorders
  adjustorders
  
  $turn += 1
  refreshunits
  playerorders
  unitorders
  income
  upkeep
  
  Report.writereports
  removeplayers
  Save.save
end

