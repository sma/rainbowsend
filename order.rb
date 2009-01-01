# order.rb - Rainbow's End is an empire building strategy PBEM game
# rules (C)2001 Russell Wallace, source code (C)2001 Stefan Matthias Aust

class Order
  Ordertypes = [
    "build",
    "drop",
    "email",
    "fire",
    "friendly",
    "give",
    "group",
    "hostile",
    "move",
    "name",
    "null",
    "quit",
    "ungroup",
    "wait",
  ]
  # create order constants via meta-magic
  Ordertypes.each_with_index {|o, i| const_set o.capitalize, i}
  
  attr_reader :type, :args
  attr_writer :type
  
  def initialize(type, args)
    @type, @args = type, args
  end
end

Maxorders = 100

def read(file) #private
  while true
    line = file.gets
    return nil if !line
    words = parse(line)
    return words if !words.empty?
  end
end

def findtype(s) #private
  return -1 if !s
  order = Order::Ordertypes.detect{|each| s.downcase == each[0, s.length]}
  Order::Ordertypes.index(order) || -1
end

def addorder(e, words) #private
  type = findtype(words[0])
  if type < 0
    e.quote(*words)
    e.event("Order not recognized")
    return
  end
  
  if e.orders.length >= Maxorders
    e.event("Maximum number of orders reached")
    return
  end

  e.orders.add(Order.new(type, words[1..-1]))
end

def readorders
  begin
    file = File.open("orders", "r")
    words = read(file)
  
    while true
      while words[0].downcase != 'player'
        (words = read(file)) || return
      end
     
      p = findplayer(words[1].to_i)
      if !p
        words = read(file)
        next
      end
      
      p.orders.clear
      p.lastorders = $turn + 1
      p.units.each {|u| u.orders.clear}
      
      while true
        (words = read(file)) || return
        w = words[0].downcase
        break if w == 'unit' || w == 'end' || w == 'player'
        addorder(p, words)
      end #player orders
      
      while words[0].downcase == 'unit'
        u = findunit(p, words[1].to_i)
        if !u
          p.quote(*words)
          p.event("You have no such unit")
          begin
            (words = read(file)) || return
            w = words[0].downcase
          end until w == 'unit' || w == 'end' || w == 'player'
          next
        end
        
        while true
          (words = read(file)) || return
          w = words[0].downcase
          if w == 'unit' || w == 'end' || w == 'player'
            break
          end
          addorder(u, words)
        end
      end #unit orders
    end
  rescue
    raise "Orders file not found"
  ensure
    file.close
  end
end

def adjustorders_(e) #private
  e.orders.each do |o|
    next if o.type != Order::Wait
    o.type = Order::Null
    i = e.orders.index(o) + 1
    while e.orders.length < Maxorders
      e.orders[i,0] = Order.new(Order::Null, [])
    end
  end
end

def adjustorders
  $players.each {|p| adjustorders_(p)}
  $units.each {|p| adjustorders_(p)}
end

def doorder(p, o)
  if p.is_a? Unit
    doorder2(p, o) 
    return
  end
  type = o.type
  return if type == Order::Null
  p.quote(Order::Ordertypes[type], *o.args)
  case type
  when Order::Email
    email(p, o.args)
  when Order::Friendly
    friendly(p, o.args)
  when Order::Give
    give(p, o.args)
  when Order::Hostile
    hostile(p, o.args)
  when Order::Name
    name(p, o.args)
  when Order::Quit
    quit(p)
  else
    p.event "That order must be issued for a specific unit"
  end
end

def doorder2(u, o) # XXX conflict removed by hack
  type = o.type
  return if type == Order::Null
  u.quote(Order::Ordertypes[type], *o.args)
  case type
  when Order::Build
    build(u, o.args)
  when Order::Drop
    drop(u)
  when Order::Email
    email(u.player, o.args)
  when Order::Fire
    fire(u, o.args)
  when Order::Group
    group(u, o.args)
  when Order::Move
    move(u, o.args)
  when Order::Name
    name(u, o.args)
  when Order::Quit
    quit(u.player)
  when Order::Ungroup
    ungroup(u, o.args)
  else
    u.event "That order must be issued for your empire as a whole"
  end
end

