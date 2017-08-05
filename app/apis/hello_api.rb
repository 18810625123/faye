require 'rack/cors'

class HelloApi < Grape::API


  use Rack::Cors do
    allow do
      origins '*'
      resource '*', headers: :any, methods: :get
    end
  end

  format :json

  get 'get_users_by_channel' do
    channel = params[:channel]
    if channel
      users = $waiter.users[channel]
      {ok:true,msg:users}
    else
      {ok:false,msg:'缺少 channel 参数'}
    end
  end

end
