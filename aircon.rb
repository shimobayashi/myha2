#!/usr/bin/env ruby

require 'json'

AIRCON_COOLER_ON_THRESHOLD = 79.5
AIRCON_COOLER_OFF_THRESHOLD = 78.0
AIRCON_HEATER_ON_THRESHOLD = 60.0
AIRCON_HEATER_OFF_THRESHOLD = 65.0

def aircon_cooler_on
  #%x[ curl http://192.168.10.18/messages -d `cat aircon_on_cooler_27.irkit` ]
  %x[ curl http://192.168.10.18/messages -d `cat aircon_on_dehumidify_28.irkit` ]
  puts "cooloer_on: #{$?}"
  sleep 0.5
  epoch = Time.now.to_i
  `curl #{ENV['JSONJAR_ROOT']}?aircon_on_cooler_27=#{epoch}`
end

def aircon_heater_on
  %x[ curl http://192.168.10.18/messages -d `cat aircon_on_heater_25.irkit` ]
  puts "heater_on: #{$?}"
  sleep 0.5
  epoch = Time.now.to_i
  `curl #{ENV['JSONJAR_ROOT']}?aircon_on_heater_25=#{epoch}`
end

def aircon_off
  %x[ curl http://192.168.10.18/messages -d `cat aircon_off.irkit` ]
  puts "off: #{$?}"
  sleep 0.5
  `curl #{ENV['JSONJAR_ROOT']}?aircon_on_cooler_27=0`
  `curl #{ENV['JSONJAR_ROOT']}?aircon_on_heater_25=0`
end

settings = JSON.parse(STDIN.read)
p settings

if settings['home'] != '0' # 在宅中
  diff = Time.now.to_i - (settings['sleep'] || '0').to_i
  p diff
  if diff < 120 # 赤外線LEDの向きがあってるか確認するため&エアコン手動でつけっぱだったら同期するためにOFFを送る
    aircon_off
  else
    discomfort_index = settings['discomfort_index'].to_f

    # 冷房
    if (discomfort_index > AIRCON_COOLER_ON_THRESHOLD && settings['sleep'] != '0') && settings['aircon_on_cooler_27'] == '0'
      aircon_cooler_on
    elsif (discomfort_index < AIRCON_COOLER_OFF_THRESHOLD || settings['sleep'] == '0') && settings['aircon_on_cooler_27'] != '0'
      aircon_off
    end

    # 暖房
    if (discomfort_index < AIRCON_HEATER_ON_THRESHOLD && settings['sleep'] != '0') && settings['aircon_on_heater_25'] == '0'
      if diff > 7.5 * 60 * 60 # 就寝から7時間以上経過
        aircon_heater_on
      end
    elsif (discomfort_index > AIRCON_HEATER_OFF_THRESHOLD || settings['sleep'] == '0') && settings['aircon_on_heater_25'] != '0'
      aircon_off
    end
  end
else
  diff = Time.now.to_i - (settings['away'] || '0').to_i
  p diff
  if diff < 120 # 家を出たらエアコンを切る
    aircon_off
  end
end
