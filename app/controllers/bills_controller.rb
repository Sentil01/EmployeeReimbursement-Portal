class BillsController < ApplicationController
  before_action :set_bill, only: [:show, :approve, :reject, :revoke_approval, :revoke_rejection]
  before_action :ensure_employee, only: [:new, :create]
  before_action :ensure_admin, only: [:approve, :reject, :revoke_approval, :revoke_rejection]

  def index
    if is_admin?
      @bills = Bill.includes(:employee).order(created_at: :desc)
      @total_submitted = Bill.total_submitted
      @total_approved = Bill.total_approved
    else
      @employee = current_user.employee
      if @employee
        @bills = @employee.bills.order(created_at: :desc)
        @total_submitted = @employee.total_bills_amount
        @total_approved = @employee.total_approved_amount
      else
        @bills = Bill.none
        @total_submitted = 0
        @total_approved = 0
      end
    end
  end

  def show
    unless is_admin?
      employee = current_user.employee
      if employee.nil? || @bill.employee_id != employee.id
        redirect_to bills_path, alert: 'Access denied. You can only view your own bills.'
        return
      end
    end
  end

  def new
    @employee = current_user.employee
    if @employee.nil?
      redirect_to root_path, alert: "You need to be associated with an employee record to submit bills."
      return
    end
    @bill = Bill.new
  end

  def create
    @employee = current_user.employee
    if @employee.nil?
      redirect_to root_path, alert: "You need to be associated with an employee record to submit bills."
      return
    end
    
    @bill = @employee.bills.build(bill_params)
    @bill.status = 'pending'
    @bill.submitted_by = @employee.full_name

    if @bill.save
      redirect_to bills_path, notice: "Bill submitted successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def approve
    @bill.approve!
    redirect_to bills_path, notice: "Bill approved successfully."
  rescue => e
    redirect_to bills_path, alert: e.message
  end

  def reject
    @bill.reject!
    redirect_to bills_path, notice: "Bill rejected successfully."
  rescue => e
    redirect_to bills_path, alert: e.message
  end

  def revoke_approval
    @bill.revoke_approval!
    redirect_to bills_path, notice: "Bill approval revoked successfully."
  rescue => e
    redirect_to bills_path, alert: e.message
  end

  def revoke_rejection
    @bill.revoke_rejection!
    redirect_to bills_path, notice: "Bill rejection revoked successfully."
  rescue => e
    redirect_to bills_path, alert: e.message
  end

  private

  def set_bill
    @bill = Bill.find(params[:id])
  end

  def bill_params
    params.require(:bill).permit(:amount, :bill_type)
  end
end

