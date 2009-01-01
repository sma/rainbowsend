# entity.rb - Rainbow's End is an empire building strategy PBEM game
# rules (C)2001 Russell Wallace, source code (C)2001 Stefan Matthias Aust

class Entity
  attr_accessor :id, :name
  attr_reader :orders, :events
  
  def initialize
    @orders = []
    @events = []
  end
  
  def nameid
    "#{@name} [#{@id}]"
  end
  
  def event(*args)
    @events.add("#{$slot}: #{args.join(' ')}.")
  end
  
  def quote(*args)
    buf = "#{$slot}: >"
    args.each do |arg|
      buf << " "
      arg = arg.to_s
      if arg =~ / /
        buf << '"' << arg << '"'
      else
        buf << arg
      end
    end
    @events.add(buf)
  end
end

