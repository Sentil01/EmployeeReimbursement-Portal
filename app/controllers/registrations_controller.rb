class RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]
  before_action :load_departments, only: [:new, :create]
  
  def new
    super
  end

  def create
    @departments = Department.all
    super do |resource|
      if resource.persisted? && resource.role == 'employee'
        if params[:employee].blank?
          resource.errors.add(:base, "Employee details are required")
          resource.destroy
          render :new and return
        end
        
        employee = Employee.new(
          first_name: params[:employee][:first_name],
          last_name: params[:employee][:last_name],
          email: resource.email,
          designation: params[:employee][:designation],
          department_id: params[:employee][:department_id],
          user_id: resource.id
        )
        
        unless employee.save
          resource.errors.add(:base, "Failed to create employee record: #{employee.errors.full_messages.join(', ')}")
          resource.destroy
          render :new and return
        end
      end
    end
  end

  protected

  def load_departments
    @departments = Department.all
  end

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :role, employee: [:first_name, :last_name, :designation, :department_id]])
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :role])
  end
end

