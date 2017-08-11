class SessionsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    if auth_hash = request.env["omniauth.auth"]
      oauth_name = request.env["omniauth.auth"]["info"]["name"]
      oauth_email = request.env["omniauth.auth"]["info"]["email"]
      if user = User.find_by(email: oauth_email)
        session[:user_id] = user.id
      else
        random_pass = SecureRandom.hex
        user = User.new(username: oauth_name, email: oauth_email, password: random_pass, password_confirmation: random_pass)
        if user.save
          session[:user_id] = user.id
          redirect_to home_path
        else
          redirect_to home_path, error: 'Oauth Failure, please try again'
        end
      end
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
    redirect_to home_path
  end

  private

  def auth
    request.env['omniauth.auth']
  end
end
