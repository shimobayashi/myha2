#!/usr/bin/env ruby

require 'json'

AIRCON_COOLER_ON_THRESHOLD = 81.3
AIRCON_COOLER_OFF_THRESHOLD = 79.1
AIRCON_HEATER_ON_THRESHOLD = 60.0
AIRCON_HEATER_OFF_THRESHOLD = 65.0

def aircon_cooler_on
  `irsend SEND_ONCE aircon on_cooler_27`
  puts "cooloer_on: #{$?}"
  sleep 0.5
  `irsend SEND_ONCE aircon on_cooler_27`
  puts "cooloer_on: #{$?}"
  epoch = Time.now.to_i
  `curl #{ENV['JSONJAR_ROOT']}?aircon_on_cooler_27=#{epoch}`
end

def aircon_heater_on
  `irsend SEND_ONCE aircon on_heater_25`
  puts "heater_on: #{$?}"
  sleep 0.5
  `irsend SEND_ONCE aircon on_heater_25`
  puts "heater_on: #{$?}"
  epoch = Time.now.to_i
  `curl #{ENV['JSONJAR_ROOT']}?aircon_on_heater_25=#{epoch}`
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

diff = Time.now.to_i - (settings['sleep'] || '0').to_i
p diff
if diff < 120 # 赤外線LEDの向きがあってるか確認するため&エアコン手動でつけっぱだったら同期するためにOFFを送る
  aircon_off
else
  discomfort_index = settings['discomfort_index'].to_f

  # 冷房
  if (discomfort_index > AIRCON_COOLER_ON_THRESHOLD && settings['home'] != '0' && settings['sleep'] != '0') && settings['aircon_on_cooler_27'] == '0' # 在宅中かつ就寝中
    aircon_cooler_on
  elsif (discomfort_index < AIRCON_COOLER_OFF_THRESHOLD || settings['home'] == '0' || settings['sleep'] == '0') && settings['aircon_on_cooler_27'] != '0'
    aircon_off
  end

  # 暖房
  if (discomfort_index < AIRCON_HEATER_ON_THRESHOLD && settings['home'] != '0' && settings['sleep'] != '0') && settings['aircon_on_heater_25'] == '0' # 在宅中かつ就寝中
    if diff > 7 * 60 * 60 # 就寝から7時間以上経過
      aircon_heater_on
    end
  elsif (discomfort_index > AIRCON_HEATER_ON_THRESHOLD || settings['home'] == '0' || settings['sleep'] == '0') && settings['aircon_on_heater_25'] != '0'
    aircon_off
  end
end
