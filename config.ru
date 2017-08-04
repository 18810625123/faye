# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'


require 'faye'
bayeux = Faye::RackAdapter.new(:mount => '/faye', :timeout => 25)





class FayeWaiter

  ActiveRecord::Base.logger=false

  attr_accessor :users, :channels, :clientids, :online_users, :msg_list

  def initialize
    @msg_list = []
    @online_users = {}
    @channels = {}
    ['/douyu','/lol'].each do |channel|
      @channels[channel] = {online_users:{}}
      @online_users[channel] = {}
    end
    @clientids = {}
  end

  # 用户通过rails服务器验证后,通知这边,加入列表
  def user_online channel, user
    @online_users[channel].store(user['id'], user)
    puts "用户上线  #{channel}:id(#{user['id']}),name(#{user['name']})"
  end

  # 用户下线
  def user_offline channel_id
    if @clientids[client_id]
      channel = @clientids[client_id][:channel]
      user_id = @clientids[client_id][:user_id]
      @online_users[channel].delete(id)
      puts "用户下线  #{channel}:id(#{user_id})"
    else
      raise "系统出错,没有这个id不存在连接列表中:#{channel_id}"
    end
  end

  def incoming(message, callback)
    handle message if message['channel'].match(/^\/meta/)

    if message['data']
      channel = message['channel']
      data = message['data']
      user = message['data']['user']
      puts "#{data['type']}:#{data['channel']}\t#{data['username']}:#{data['text']}"
      case data['type']
        when 'sub'
          user_online(channel, user)
          @clientids[message['clientId']][:user_id] = user['id']
        when 'pub'
          msg = {user_id:user['id'], username:user['name'], text:data['text'], category:data['type'], ip:user['ip'], channel:channel}
          @msg_list << msg
          Msg.create(msg)
        when 'unsub'
          user_offline message['clientId']
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
        @clientids[message["clientId"]] = {channel:message['subscription'],user_id:nil,last_conn:Time.now}
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

Thread.new do
  loop do
    t1 = Time.now
    puts '当前时间:'+t1.to_s
    debugger

    sleep 60

    $waiteronline_users.each do |channel, users|
      users.each do |id, user|
        t2 = Msg.where("user_id = #{id}").last.created_at
        puts "#{channel}:#{id}:#{t2.create}\t#{t1-t2}"
        if (t1 - t2) > 60
          users.delete id
        end
      end
    end
    
  end
end

run Rails.application


