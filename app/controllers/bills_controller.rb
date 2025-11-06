class BillsController < ApplicationController
  before_action :set_bill, only: [:show, :approve, :reject, :revoke_approval, :revoke_rejection]
  before_action :ensure_employee, only: [:new, :create]
  before_action :ensure_admin, only: [:approve, :reject, :revoke_approval, :revoke_rejection]

  def index
    if is_admin?
      @bills = Bill.includes(:employee).order(created_at: :desc)
      @total_submitted = Bill.sum(:amount)
      @total_approved = Bill.where(status: 'approved').sum(:amount)
    else
      @employee = current_user.employee
      if @employee
        @bills = @employee.bills.order(created_at: :desc)
        @total_submitted = @employee.bills.sum(:amount)
        @total_approved = @employee.bills.where(status: 'approved').sum(:amount)
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
    if @bill.status != 'pending'
      redirect_to bills_path, alert: "This bill has already been processed."
      return
    end
    
    if @bill.update(status: 'approved')
      redirect_to bills_path, notice: "Bill approved successfully."
    else
      redirect_to bills_path, alert: "Failed to approve bill."
    end
  end

  def reject
    if @bill.status != 'pending'
      redirect_to bills_path, alert: "This bill has already been processed."
      return
    end
    
    if @bill.update(status: 'rejected')
      redirect_to bills_path, notice: "Bill rejected successfully."
    else
      redirect_to bills_path, alert: "Failed to reject bill."
    end
  end

  def revoke_approval
    if @bill.status != 'approved'
      redirect_to bills_path, alert: "This bill is not approved."
      return
    end
    
    if @bill.update(status: 'pending')
      redirect_to bills_path, notice: "Bill approval revoked successfully."
    else
      redirect_to bills_path, alert: "Failed to revoke approval."
    end
  end

  def revoke_rejection
    if @bill.status != 'rejected'
      redirect_to bills_path, alert: "This bill is not rejected."
      return
    end
    
    if @bill.update(status: 'pending')
      redirect_to bills_path, notice: "Bill rejection revoked successfully."
    else
      redirect_to bills_path, alert: "Failed to revoke rejection."
    end
  end

  private

  def set_bill
    @bill = Bill.find(params[:id])
  end

  def bill_params
    params.require(:bill).permit(:amount, :bill_type)
  end
end

