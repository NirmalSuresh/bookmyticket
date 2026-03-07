class AddPaymentFieldsToBookings < ActiveRecord::Migration[7.1]
  def change
    add_column :bookings, :razorpay_order_id, :string
    add_column :bookings, :razorpay_payment_id, :string
    add_column :bookings, :razorpay_signature, :string
    add_column :bookings, :paid_at, :datetime
  end
end
