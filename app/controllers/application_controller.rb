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

  private

  def current_user
    session[:user_id] ? @current_user ||= User.find(session[:user_id]) : @current_user = nil
  end

  def authorize_user
    unless admin? || current_user == params[:id].to_i
      redirect_to home_path
    end
  end
end
