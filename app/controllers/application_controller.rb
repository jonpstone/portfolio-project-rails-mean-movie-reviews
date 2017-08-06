class ApplicationController < ActionController::Base
  add_flash_types(:error, :notice, :alert)
  protect_from_forgery with: :exception
  helper_method :current_user, :admin?, :logged_in?, :authorized?

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
end
