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

  # POST /employees or /employees.json
  def create
    @employee = Employee.new(employee_params)
    @departments = Department.all

    if @employee.save
      user = User.find_by(email: @employee.email)
      temp_password = nil
      
      unless user
        temp_password = SecureRandom.hex(8)
        user = User.create!(
          name: @employee.full_name,
          email: @employee.email,
          password: temp_password,
          password_confirmation: temp_password,
          role: 'employee'
        )
        @employee.update(user_id: user.id)
        flash[:notice] = "Employee was successfully created. User account created. Temporary password: #{temp_password}"
      else
        if user.employee.nil?
          @employee.update(user_id: user.id)
          flash[:notice] = "Employee was successfully created and linked to existing user account."
        else
          flash[:alert] = "Employee was created, but email already has a user account linked to another employee."
        end
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
