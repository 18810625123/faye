# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'


require 'faye'
bayeux = Faye::RackAdapter.new(:mount => '/faye', :timeout => 25)





class FayeWaiter

  ActiveRecord::Base.logger=false

  attr_accessor :users, :channels

  def initialize
    @channels = []
    @users = {}
    Channel.all.each do |c|
      @channels << c.name
      @users[c.name] = {}
    end

    begin
      Thread.start do
        loop do
          sleep 600
          puts '-----------------------'
          t1 = Time.now
          @users.each do |channel, users|
            users.each do |id, user|
              msg = Msg.where("user_id = #{id}").last
              t2 = msg.created_at
              puts "#{channel}频道:当前在线用户 #{user['name']} id:#{id} 最后一条消息: text:#{msg.text}, date:#{t2.to_s}  距离秒:#{t1 - t2}"
              if (t1 - t2) > 600
                users.delete id
              end
            end
          end
          puts '-----------------------'
        end
      end
    rescue
      puts $!
      ptus $@
    end
puts 2
  end


  def incoming(message, callback)
    handle message if message['channel'].match(/^\/meta/)

    if message['data']
      channel = message['channel']

      if !@channels.include?(channel)
        puts '不存在此频道:' +channel
        return
      end

      data = message['data']
      user = message['data']['user']
      puts "#{data['type']}:#{data['channel']}\t#{data['username']}:#{data['text']}"
      case data['type']
        when 'sub'
          @users[channel][user['id']] = user
          msg = {user_id:user['id'], username:user['name'], text:data['text'], category:data['type'], ip:user['ip'], channel:channel}
          Msg.create(msg)
        when 'pub'
          msg = {user_id:user['id'], username:user['name'], text:data['text'], category:data['type'], ip:user['ip'], channel:channel}
          Msg.create(msg)
        when 'unsub'
          puts "有用户用户下线:"
        else
          puts "不存在的消息类型: #{data['type']}"
          return
      end

    end
    callback.call(message)
  end

  def handle message
    case message['channel'].split('/')[2]
      when 'handshake'
        # {"channel"=>"/meta/handshake",
        #  "version"=>"1.0",
        #  "supportedConnectionTypes"=>["websocket", "eventsource", "long-polling", "cross-origin-long-polling", "callback-polling"],
        #  "id"=>"z"}
        puts "握手\tversion:#{message['version']}\tid:#{message['id']}\tsupportedConnectionTypes:#{message['supportedConnectionTypes']}"
      when 'subscribe'
        # {"channel"=>"/meta/subscribe",
        #  "clientId"=>"8w5w4qtnw9bczhvkq5zwoyi6kuosuhs",
        #  "subscription"=>"/oa_fm/1",
        #  "id"=>"11"}
        puts "订阅\tsubscription:#{message['subscription']}\tid:#{message['id']}\tclientId:#{message['clientId']}\t"
      when 'connect'
        # {"channel"=>"/meta/connect",
        #  "clientId"=>"johyl8m7kaw1jkxxp5mwcmxb9o7cxa7",
        #  "connectionType"=>"cross-origin-long-polling",
        #  "id"=>"y"}
        puts "连接\tid:#{message['id']}\tclientId:#{message['clientId']}\tconnectionType:#{message['connectionType']}"
      when 'disconnect'
        # {"channel"=>"/meta/disconnect",
        #  "clientId"=>"8w5w4qtnw9bczhvkq5zwoyi6kuosuhs",
        #  "id"=>"12"}
        user_offline message['clientId']

        puts "退订\tid:#{message['id']}\tclientId:#{message['clientId']}"
      else
        puts "未知的meta类型 => #{method}"
        puts "未知的meta类型 => #{method}"
        puts "未知的meta类型 => #{method}"
        puts "未知的meta类型 => #{method}"
        puts "未知的meta类型 => #{method}"
    end
  end

end

$waiter = FayeWaiter.new

use Faye::RackAdapter, :mount => '/faye', :timeout => 25 do |bayeux|
  bayeux.add_extension($waiter)
end

run Rails.application


