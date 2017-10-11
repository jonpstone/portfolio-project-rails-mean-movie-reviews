class SessionsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    if auth_hash = request.env["omniauth.auth"]
      user = User.find_or_create_by_omniauth(auth_hash)
      session[:user_id] = user.id
      redirect_to home_path
    else
      user = User.find_by(email: params[:user][:email])
      if user && user.try(:authenticate, params[:user][:password])
        session[:user_id] = user.id
        redirect_to home_path, notice: 'Sign in successful'
      else
        return redirect_to signin_path, error: 'Email or password incorrect'
      end
    end
  end

  def destroy
    session.clear
    redirect_to home_path, notice: 'You have been logged out'
  end
end
