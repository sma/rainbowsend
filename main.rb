#!/usr/bin/env ruby -w
# main.rb - Rainbow's End is an empire building strategy PBEM game
# rules (C)2001 Russell Wallace, source code (C)2001 Stefan Matthias Aust

load "entity.rb"
load "game.rb"
load "map.rb"
load "misc.rb"
load "options.rb"
load "order.rb"
load "parse.rb"
load "player.rb"
load "rules.rb"
load "save.rb"
load "unit.rb"
load "writerpt.rb"
load "ai.rb"

# I thought these methods would exist
class Array 
  alias :add :<<
  alias :remove :delete
end

# these methods should exist IMHO
class Integer 
  def odd
    (self & 1) == 1
  end
  def even
    (self & 1) == 0
  end
  def sign
    self <=> 0
  end
end

# main
case ARGV[0]
when "--new"
  newgame
when "--turn"
  runturn
when "--update"
  Save.load
  6.times do
    begin
      h = $hexes[rand($hexes.length)]
    end while h.water? || cityarea(h)
    u = Unit.new(1, "Ruins", Unit::Ruins, $players.last, h.h)
    nextid(u)
    addunit(u)
  end
  Save.save
when "--version"
  print "Rainbow's End version 1.2.x\n"
  print "Rules Copyright 2001 by Russell Wallace\n"
  print "Sourcecode Copyright 2001 by Stefan Matthias Aust\n"
  print "This program is free software.\n"
  print "See license for details.\n"
else
  $stderr.print "usage: #{$0} {--new | --turn | --version}\n"
  #exit 1
end

