require 'rack/cors'

class HelloApi < Grape::API


  use Rack::Cors do
    allow do
      origins '*'
      resource '*', headers: :any, methods: :get
    end
  end

  format :json

  get 'get_online_users' do
    if params[:channel]
      {ok:true,msg:$waiter.online_users[params[:channel]]}
    else
      {ok:false,msg:'缺少 channel 参数'}
    end
  end

end
