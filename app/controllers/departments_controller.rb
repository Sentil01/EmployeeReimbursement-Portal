class DepartmentsController < ApplicationController
  before_action :ensure_admin
  before_action :set_department, only: %i[ show edit update destroy ]

  def index
    @departments = Department.all
  end

  def show
  end

  def new
    @department = Department.new
  end

  def edit
  end

  def create
    @department = Department.new(department_params)

    if @department.save
      redirect_to @department, notice: "Department was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @department.update(department_params)
      redirect_to @department, notice: "Department was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @department.employees.any?
      redirect_to departments_path, alert: "Cannot delete department with existing employees."
    else
      @department.destroy
      redirect_to departments_path, notice: "Department was successfully deleted."
    end
  end

  private

  def set_department
    @department = Department.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to departments_path, alert: 'Department not found.'
  end

  def department_params
    params.require(:department).permit(:name)
  end
end

