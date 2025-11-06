class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  before_action :authenticate_user!

  def is_admin?
    current_user&.role == 'admin'
  end

  def is_employee?
    current_user&.role == 'employee'
  end

  def ensure_admin
    redirect_to root_path, alert: 'Access denied. Admin only.' unless is_admin?
  end
  
  def ensure_employee
    redirect_to root_path, alert: 'Access denied. Employee only.' unless is_employee?
  end

  helper_method :is_admin?, :is_employee?
end
