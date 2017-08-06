class ApplicationController < ActionController::Base
  add_flash_types(:error, :notice, :alert)
  protect_from_forgery with: :exception
end
