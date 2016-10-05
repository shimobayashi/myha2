#!/usr/bin/env ruby

require 'json'

SMART_PERIOD_SPAN = 10 * 60; # スマートウェイクアップの許容範囲の設定時間

puts 'read settings...'

settings = JSON.parse(STDIN.read)
p settings

exit if settings['manual_led'] == '1' # 手動運転中

cmd = nil
cmd2 = nil
if settings['home'] == '0' # 外出中
  cmd = "\\x41\\x00\\x55" # 消灯
else # 在宅中
  if settings['sleep'] == '0' # 寝てない
    t = Time.now
    p t

    if (settings['lux'] || '0').to_i > 3000 # 日中でカーテンを両方開けていれば電気をつけない
      cmd = "\\x41\\x00\\x55" # 消灯
    elsif (settings['lux'] || '0').to_i <= 2500 # 日中でカーテン片方閉じたくらいの暗さであれば電気をつける
      cmd = "\\x42\\x00\\x55" # 点灯
      if settings['time_to_sleep'] != '0' # 寝る時間
        cmd2 = "\\x40\\xa0\\x55" # 赤色
      elsif (t.hour >= 23 || t.hour < 5) # 23時～5時
        cmd2 = "\\x40\\x95\\x55" # 赤っぽい暖色
      elsif t.hour >= 21 # 21時～23時
        cmd2 = "\\x40\\x90\\x55" # 暖色
      else
        cmd2 = "\\xC2\\x00\\x55" # 白色
      end
    end
  else # 寝てる
    # アラート近くで電灯を軽く点けて目覚ましをうながす
    # auto_start_sleep_trackはスマートウェイクアップの45分前のunixtimeが設定される
    # つまり、 アラート時刻=auto_start_sleep_track+45*60+SMART_PERIOD_SPAN で求められる
    alert_time = (settings['auto_start_sleep_track'] || '0').to_i + 45 * 60 + SMART_PERIOD_SPAN
    diff = Time.now.to_i - alert_time
    p diff
    if (diff > -(SMART_PERIOD_SPAN + 0 * 60) && (diff < 0 * 60) # アラートスマートピリオド+0分前～0分後まで
      cmd = "\\x42\\x00\\x55" # 点灯
      cmd2 = "\\x40\\xa0\\x55" # 赤色
    else
      cmd = "\\x41\\x00\\x55" # 消灯
    end
  end
end

p cmd
if cmd
  p `bash -c 'echo -ne "#{cmd}" > /dev/udp/192.168.10.16/8899'`
  p $?
end
p cmd2
if cmd2
  sleep 0.1
  p `bash -c 'echo -ne "#{cmd2}" > /dev/udp/192.168.10.16/8899'`
  p $?
end
