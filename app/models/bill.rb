class Bill < ApplicationRecord
  belongs_to :employee

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :bill_type, presence: true, inclusion: { in: %w[food travel others] }
  validates :status, presence: true, inclusion: { in: %w[pending approved rejected] }
  validates :employee_id, presence: true

  scope :pending, -> { where(status: 'pending') }
  scope :approved, -> { where(status: 'approved') }
  scope :rejected, -> { where(status: 'rejected') }

  def approve!
    raise "Bill must be pending to approve" unless status == 'pending'
    update!(status: 'approved')
  end

  def reject!
    raise "Bill must be pending to reject" unless status == 'pending'
    update!(status: 'rejected')
  end

  def revoke_approval!
    raise "Bill must be approved to revoke approval" unless status == 'approved'
    update!(status: 'pending')
  end

  def revoke_rejection!
    raise "Bill must be rejected to revoke rejection" unless status == 'rejected'
    update!(status: 'pending')
  end

  def self.total_submitted
    sum(:amount)
  end

  def self.total_approved
    approved.sum(:amount)
  end
end
