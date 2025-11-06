class Bill < ApplicationRecord
  belongs_to :employee

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :bill_type, presence: true, inclusion: { in: %w[food travel others] }
  validates :status, presence: true, inclusion: { in: %w[pending approved rejected] }
  validates :employee_id, presence: true
end
