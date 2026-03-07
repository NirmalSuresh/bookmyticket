# Email configuration for BookMyTicket
Rails.application.configure do
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default_options = { from: ENV.fetch('MAILER_FROM', 'noreply@bookmyticket.com') }
end
