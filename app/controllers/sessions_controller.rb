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

  def destroy
    session.clear
    redirect_to home_path
  end
end
