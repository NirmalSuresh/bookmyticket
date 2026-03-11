Rails.application.config.content_security_policy do |policy|
  policy.default_src :self, :https
  policy.img_src     :self, :https, :data
  policy.object_src  :none
  policy.script_src  :self, :unsafe_inline
  policy.style_src   :self, :unsafe_inline, "https://fonts.googleapis.com"
  policy.font_src    :self, :https, :data, "https://fonts.gstatic.com"
  policy.connect_src :self, :https
  policy.base_uri    :self
end
