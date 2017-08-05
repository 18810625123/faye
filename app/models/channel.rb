class Channel < ApplicationRecord

  def users
    if @users
      @users
    else
      @users = []
    end
  end

  def add_user user
    users << user
  end

  def user_exist?
    puts users.size
  end

end
