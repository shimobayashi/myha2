#!/usr/bin/env ruby

require 'json'

AIRCON_COOLER_ON_THRESHOLD = 81
AIRCON_COOLER_OFF_THRESHOLD = 79

def aircon_cooler_on
  `irsend SEND_ONCE aircon on_cooler_27`
  puts "cooloer_on: #{$?}"
  sleep 0.5
  `irsend SEND_ONCE aircon on_cooler_27`
  puts "cooloer_on: #{$?}"
  epoch = Time.now.to_i
  `curl #{ENV['JSONJAR_ROOT']}?aircon_on_cooler_27=#{epoch}`
end

def aircon_off
  `irsend SEND_ONCE aircon off`
  puts "off: #{$?}"
  sleep 0.5
  `irsend SEND_ONCE aircon off`
  puts "off: #{$?}"
  `curl #{ENV['JSONJAR_ROOT']}?aircon_on_cooler_27=0`
end

settings = JSON.parse(STDIN.read)
p settings

discomfort_index = settings['discomfort_index'].to_f
if (discomfort_index > AIRCON_COOLER_ON_THRESHOLD && settings['home'] != '0' && settings['sleep'] != '0') && settings['aircon_on_cooler_27'] == '0' # 在宅中かつ就寝中
  aircon_cooler_on
elsif (discomfort_index < AIRCON_COOLER_OFF_THRESHOLD || settings['home'] == '0' || settings['sleep'] == '0') && settings['aircon_on_cooler_27'] != '0'
  aircon_off
end
