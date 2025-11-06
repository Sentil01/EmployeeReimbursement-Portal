class Employee < ApplicationRecord
  belongs_to :department
  belongs_to :user, optional: true
  has_many :bills, dependent: :destroy

  validates :first_name, :last_name, :email, :designation, presence: true
  validates :email, uniqueness: true
  validates :department_id, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end
end
