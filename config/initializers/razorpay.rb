# Razorpay configuration for BookMyTicket
Rails.application.configure do
  config.razorpay_key_id = ENV['RAZORPAY_KEY_ID'] || 'rzp_test_1234567890abcdef'
  config.razorpay_key_secret = ENV['RAZORPAY_KEY_SECRET'] || 'test_secret_1234567890abcdef'
end
