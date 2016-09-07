#!/usr/bin/env ruby

T = 425

open(ARGV[0]).readlines.each {|line|
  line =~ /^(\w+) (\d+)$/
  type = $1
  interval = $2.to_i
  aligned_interval = nil

  if (interval > 49000)
    aligned_interval = 50000
  elsif (interval > 29000)
    aligned_interval = 30000
  elsif (interval > 3200)
    aligned_interval = T * 8
  elsif (interval > 1500)
    aligned_interval = T * 4
  elsif (interval > 1100)
    aligned_interval = T * 3
  elsif (interval > 300)
    aligned_interval = T * 1
  else
    abort 'invalid interval: ' + interval
  end

  puts sprintf("%s %d", type, aligned_interval)
}
