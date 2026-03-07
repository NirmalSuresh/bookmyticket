class PaymentService
  require 'razorpay'
  
  def self.create_order(amount, booking_id)
    Razorpay.setup(Rails.application.config.razorpay_key_id, Rails.application.config.razorpay_key_secret)
    
    options = {
      amount: amount * 100, # Razorpay expects amount in paise
      currency: 'INR',
      receipt: "booking_#{booking_id}",
      payment_capture: '1'
    }
    
    Razorpay::Order.create(options)
  end
  
  def self.verify_payment(payment_id, order_id, signature)
    Razorpay.setup(Rails.application.config.razorpay_key_id, Rails.application.config.razorpay_key_secret)
    
    attributes = {
      razorpay_order_id: order_id,
      razorpay_payment_id: payment_id,
      razorpay_signature: signature
    }
    
    Razorpay::Utility.verify_payment_signature(attributes)
  end
end
