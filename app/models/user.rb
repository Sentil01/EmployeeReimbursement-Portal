class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one :employee, dependent: :destroy

  validates :name, presence: true
  validates :role, presence: true, inclusion: { in: %w[admin employee] }

  def admin?
    role == 'admin'
  end

  def employee?
    role == 'employee'
  end
end
