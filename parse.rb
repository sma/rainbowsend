# parse.rb - Rainbow's End is an empire building strategy PBEM game
# rules (C)2001 Russell Wallace, source code (C)2001 Stefan Matthias Aust

def parse(line)
  re = /([\w,.+\-@\/]+)|\"(.*?)\"|\#.*$/
  line.scan(re).map{|a| a.compact[0]}.compact
end

