class SessionsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    user = User.find_by(email: params[:user][:email])
    user = user.try(:authenticate, params[:user][:password])
    if user
      session[:user_id] = user.id
      @user = user
      redirect_to home_path
    else
      return redirect_to signin_path, notice: 'Email or password incorrect'
    end
  end

  def facebook
    @user = User.find_or_create_by(uid: auth['uid']) do |u|
      u.username = auth['info']['name']
      u.email = auth['info']['email']
    end
    session[:user_id] = @user.id
    render 'home/index'
  end

  def destroy
    session.clear
    redirect_to home_path
  end

  private

  def auth
    request.env['omniauth.auth']
  end
end
