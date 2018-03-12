#!/usr/bin/env ruby

require 'json'

AIRCON_COOLER_ON_THRESHOLD = 79.25
AIRCON_COOLER_OFF_THRESHOLD = 77.75
AIRCON_HEATER_ON_THRESHOLD = 60.0
AIRCON_HEATER_OFF_THRESHOLD = 65.0

current_dir = File.expand_path("..", __FILE__) + '/'

def aircon_cooler_on(irkit_file)
  irkit_file = current_dir + irkit_file
  puts "use: #{irkit_file}"
  #%x[ curl http://192.168.10.18/messages -d `cat aircon_on_cooler_27.irkit` ]
  #%x[ curl http://192.168.10.18/messages -d `cat aircon_on_dehumidify_28.irkit` ]
  #%x[ curl http://192.168.10.18/messages -d `cat aircon_on_dehumidify_27.irkit` ]
  %x[ curl http://192.168.10.18/messages -d `cat #{irkit_file}` ]
  puts "cooloer_on: #{$?}"
  sleep 0.5
  %x[ curl http://192.168.10.18/messages -d `cat #{irkit_file}` ]
  puts "cooloer_on: #{$?}"
  sleep 0.5

  epoch = Time.now.to_i
  `curl #{ENV['JSONJAR_ROOT']}?aircon_on_cooler_27=#{epoch}`
end
def aircon_cooler_27_on
  aircon_cooler_on('aircon_on_dehumidify_27.irkit')
end
def aircon_cooler_28_on
  aircon_cooler_on('aircon_on_dehumidify_28.irkit')
end

def aircon_heater_on
  irkit_file = 'aircon_on_heater_25.irkit'
  irkit_file = current_dir + irkit_file
  %x[ curl http://192.168.10.18/messages -d `cat #{irkit_file}` ]
  puts "heater_on: #{$?}"
  sleep 0.5
  %x[ curl http://192.168.10.18/messages -d `cat #{irkit_file}` ]
  puts "heater_on: #{$?}"
  sleep 0.5

  epoch = Time.now.to_i
  `curl #{ENV['JSONJAR_ROOT']}?aircon_on_heater_25=#{epoch}`
end

def aircon_off
  irkit_file = 'aircon_off.irkit'
  irkit_file = current_dir + irkit_file
  %x[ curl http://192.168.10.18/messages -d `cat #{irkit_file}` ]
  puts "off: #{$?}"
  sleep 0.5
  %x[ curl http://192.168.10.18/messages -d `cat #{irkit_file}` ]
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
    cooler_diff = Time.now.to_i - (settings['aircon_on_cooler_27'] || '0').to_i
    puts "cooler_diff: #{cooler_diff}"
    # 常に強冷房だと頻繁にON/OFFがかかって身体がおかしくなるので、段階的に冷房をつけてみる
    # 冷房ついてなかったらとりあえず弱めでつける
    if (discomfort_index > AIRCON_COOLER_ON_THRESHOLD && settings['sleep'] != '0') && settings['aircon_on_cooler_27'] == '0'
      aircon_cooler_28_on
    # 弱め冷房から1時間以上経っていたら強める
    #XXX 現状の雑な実装だと1時間毎に冷房を入れ直してビープ音が鳴ってしまうが、2時間もあれば十分に冷えて基本的には冷房オフになっているはずなのでいったん気にしない
    elsif settings['sleep'] != '0' && settings['aircon_on_cooler_27'] != '0' && cooler_diff >= 1.0 * 60 * 60
      aircon_cooler_27_on
    elsif (discomfort_index < AIRCON_COOLER_OFF_THRESHOLD || settings['sleep'] == '0') && settings['aircon_on_cooler_27'] != '0'
      aircon_off
    end

    # 暖房
    if (discomfort_index < AIRCON_HEATER_ON_THRESHOLD && settings['sleep'] != '0') && settings['aircon_on_heater_25'] == '0'
      if diff > 7.5 * 60 * 60 # 就寝から7時間半以上経過
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
