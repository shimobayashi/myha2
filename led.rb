#!/usr/bin/env ruby

require 'json'

puts 'read settings...'

settings = JSON.parse(STDIN.read)
p settings

exit if settings['manual_led'] == '1' # 手動運転中

cmd = nil
if settings['home'] == '0' # 外出中
  cmd = {"on":false} # 消灯
else # 在宅中
  if settings['sleep'] == '0' # 寝てない
    t = Time.now
    p t

    # 点灯ボタン押してから一定時間は無条件に最強の点灯する
    diff = Time.now.to_i - (settings['force_light'] || '0').to_i
    p diff
    if (diff < 60 * 20)
      cmd = {"on":true, "bri":254, "ct":153} # 点灯、寒色、明るい
    else
      if (settings['lux'] || '0').to_i > 3000 # 日中でカーテンを両方開けていれば電気をつけない
        cmd = {"on":false} # 消灯
      elsif (settings['lux'] || '0').to_i <= 2500 # 日中でカーテン片方閉じたくらいの暗さであれば電気をつける
        if settings['time_to_sleep'] != '0' # 寝る時間
          cmd = {"on":true, "bri":196, "ct":500} # 点灯、暖色、ちょっと暗い
        elsif (t.hour >= 23 || t.hour < 5) # 23時～5時
          cmd = {"on":true, "bri":254, "ct":500} # 点灯、暖色、明るい
        elsif t.hour >= 21 # 21時～23時
          cmd = {"on":true, "bri":254, "ct":250} # 点灯、寒暖色、明るい
        else
          cmd = {"on":true, "bri":254, "ct":153} # 点灯、寒色、明るい
        end
      end
    end
  else # 寝てる
    # auto_start_sleep_trackはスマートウェイクアップ=アラームが鳴りうる開始時間の45分前のunixtimeが設定される
    # なので+45分するとスマートウェイクアップ開始時間が分かる
    smart_period = (settings['auto_start_sleep_track'] || '0').to_i + 45 * 60
    diff = Time.now.to_i - smart_period
    p diff
    if (diff > 0) && (diff < 60 * 60) # スマートウェイクアップ開始後で寝ていれば灯火する。1時間以上経過していたら多分次の日の睡眠とかなので灯火しない
      cmd = {"on":true, "bri":64, "ct":500} # 点灯、暖色、かなり暗い
    else
      cmd = {"on":false} # 消灯
    end
  end
end

if cmd
  cmd = cmd.to_json.gsub(/"/, '\\"')
  p cmd
  p `curl -XPUT http://192.168.10.21/api/#{ENV['HUE_USERNAME']}/lights/1/state -d "#{cmd}"`
  p $?
end
