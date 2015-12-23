#!/usr/bin/env ruby

require 'json'

puts 'read settings...'

settings = JSON.parse(STDIN.read)
p settings

def send_cmd(cmd)
  p cmd
  p `bash -c 'echo -ne "#{cmd}" > /dev/udp/192.168.10.16/8899'`
  p $?
end

## lightとcolor, brightnessは排他
light = false
color = nil # nil = white
brightness = nil

if settings['home'] == '0' # 外出中
  light = false
else # 在宅中
  if settings['sleep'] == '0' # 寝てない
    t = Time.now
    p t

    if (settings['lux'] || '0').to_i > 3000 # 日中でカーテンを両方開けていれば電気をつけない
      light = false
    elsif (settings['lux'] || '0').to_i <= 2500 # 日中でカーテン片方閉じたくらいの暗さであれば電気をつける
      light = true
      brightness = "\\x1b" # 最大
      if settings['time_to_sleep'] != '0' # 寝る時間
        color = "\\xa0" # 赤色
        brightness = "\\x02" # 最低
      elsif (t.hour >= 23 || t.hour < 5) # 23時～5時
        color = "\\x95" # 赤っぽい暖色
      elsif t.hour >= 21 # 21時～23時
        color = "\\x90" # 暖色
      else
        color = nil # 白色
      end
    end
  else # 寝てる
    light = false
  end
end

# 点灯 or 消灯
cmd = light ? "\\x42\\x00\\x55" : "\\x41\\x00\\x55"
send_cmd(cmd)

# 色
if light
  sleep 0.1
  send_cmd("\\x42\\x00\\x55")
  sleep 0.1
  if color
    cmd = "\\x40#{color}\\x55"
    send_cmd(cmd)
  else
    cmd = "\\xC2\\x00\\x55"
    send_cmd(cmd)
  end
end

# 明るさ
if light && brightness
  sleep 0.1
  send_cmd("\\x42\\x00\\x55")
  sleep 0.1
  cmd = "\\4e#{brightness}\\x55"
  send_cmd(cmd)
end
