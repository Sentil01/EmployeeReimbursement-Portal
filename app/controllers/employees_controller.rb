class EmployeesController < ApplicationController
  before_action :ensure_admin
  before_action :set_employee, only: %i[ show edit update destroy ]

  # GET /employees or /employees.json
  def index
    @employees = Employee.includes(:department).all
  end

  # GET /employees/1 or /employees/1.json
  def show
    @employee = Employee.includes(:department, :user, :bills).find(params[:id])
  end

  # GET /employees/new
  def new
    @employee = Employee.new
    @departments = Department.all
  end

  # GET /employees/1/edit
  def edit
    @departments = Department.all
  end

  def create
    @employee = Employee.new(employee_params)
    @departments = Department.all

    if @employee.save
      result = @employee.create_user_account
      if result[:user]
        if result[:is_new]
          flash[:notice] = "Employee was successfully created. User account created. Temporary password: #{result[:temp_password]}"
        else
          flash[:notice] = "Employee was successfully created and linked to existing user account."
        end
      else
        flash[:alert] = "Employee was created, but failed to create user account: #{@employee.errors.full_messages.join(', ')}"
      end
      
      redirect_to @employee
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /employees/1 or /employees/1.json
  def update
    @departments = Department.all
    if @employee.update(employee_params)
      redirect_to @employee, notice: "Employee was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /employees/1 or /employees/1.json
  def destroy
    @employee.destroy
    redirect_to employees_path, notice: "Employee was successfully deleted."
  end

  private

  def set_employee
    @employee = Employee.find(params[:id])
  end

  def employee_params
    params.require(:employee).permit(:first_name, :last_name, :email, :designation, :department_id, :user_id)
  end
end
