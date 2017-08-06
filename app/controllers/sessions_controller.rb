class SessionsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    user = User.find_by(email: params[:user][:email])
    if user
      session[:user_id] = user.id
      redirect_to user, notice: "Welcome back #{@user.username}!"
    else
      redirect_to signin_path
    end
  end

  def destroy
    session.clear
    redirect_to home_path
  end
end
