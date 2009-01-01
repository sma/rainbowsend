# misc.rb - Rainbow's End is an empire building strategy PBEM game
# rules (C)2001 Russell Wallace, source code (C)2001 Stefan Matthias Aust

class Array
  def shuffle
    a = dup
    (a.length - 1).downto(1) do |i|
      j = rand(i + 1)
      a[i], a[j] = a[j], a[i]
    end
    a
  end
end
  
def min(i, j)
  i < j ? i : j
end

def max(i, j)
  i > j ? i : j
end
