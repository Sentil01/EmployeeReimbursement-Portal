class Employee < ApplicationRecord
  belongs_to :department
  belongs_to :user, optional: true
  has_many :bills, dependent: :destroy

  def total_bills_amount
    bills.sum(:amount)
  end

  def total_approved_amount
    bills.approved.sum(:amount)
  end

  validates :first_name, :last_name, :email, :designation, presence: true
  validates :email, uniqueness: true
  validates :department_id, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end

  def create_user_account
    return { user: user, temp_password: nil, is_new: false } if user.present?

    existing_user = User.find_by(email: email)
    if existing_user
      if existing_user.employee.nil?
        update(user_id: existing_user.id)
        return { user: existing_user, temp_password: nil, is_new: false }
      else
        errors.add(:base, "Email already has a user account linked to another employee.")
        return { user: nil, temp_password: nil, is_new: false }
      end
    end

    temp_password = SecureRandom.hex(8)
    new_user = User.create!(
      name: full_name,
      email: email,
      password: temp_password,
      password_confirmation: temp_password,
      role: 'employee'
    )
    update(user_id: new_user.id)
    { user: new_user, temp_password: temp_password, is_new: true }
  end
end
