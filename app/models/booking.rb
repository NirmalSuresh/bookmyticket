class Booking < ApplicationRecord
  belongs_to :user
  belongs_to :showtime
  
  validates :user, presence: true
  validates :showtime, presence: true
  validates :seats, presence: true
  validates :total_price, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[pending confirmed cancelled payment_failed] }
  
  serialize :seats, JSON
  
  def self.statuses
    %w[pending confirmed cancelled payment_failed]
  end
  
  def confirmed?
    status == 'confirmed'
  end
  
  def pending?
    status == 'pending'
  end
  
  def cancelled?
    status == 'cancelled'
  end
  
  def payment_failed?
    status == 'payment_failed'
  end
end
