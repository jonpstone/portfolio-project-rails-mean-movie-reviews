class ApplicationController < ActionController::Base
  add_flash_types(:error, :notice, :alert)
  protect_from_forgery with: :exception
  helper_method :current_user, :authorize_user, :admin?, :logged_in?

  def admin?
    current_user.admin
  end

  def logged_in?
    current_user
  end

  def redirection
    if !logged_in?
      redirect_to signin_path
    end
  end

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def authorize_user
    unless admin? || current_user.id == session[:user_id].to_i
      redirect_to home_path
    end
  end
end
