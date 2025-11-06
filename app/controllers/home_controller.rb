class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]

  def index
    if user_signed_in?
      if is_admin?
        @total_employees = Employee.count
        @total_bills = Bill.count
        @pending_bills = Bill.pending.count
        @approved_bills = Bill.approved.count
        @rejected_bills = Bill.rejected.count
        @total_amount_pending = Bill.pending.sum(:amount)
        @total_amount_approved = Bill.total_approved
        @recent_bills = Bill.includes(:employee).order(created_at: :desc).limit(5)
        @departments_count = Department.count
      else
        redirect_to bills_path
      end
    end
  end
end