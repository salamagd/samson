class Warden::Strategies::SessionStrategy < Warden::Strategies::Base
  def valid?
    true
  end

  def authenticate!
    # Default OmniAuth strategy
    redirect!('/auth/zendesk')
  end
end

Warden::Strategies.add(:session, Warden::Strategies::SessionStrategy)