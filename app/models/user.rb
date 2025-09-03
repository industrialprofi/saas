class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :telegram ]

  enum :subscription_plan, { free: 0, standard: 1 }, prefix: true, default: :free

  def paid?
    !subscription_plan_free?
  end

  # Daily requests quota
  FREE_DAILY_REQUESTS_LIMIT = 3
  PAID_DAILY_REQUESTS_LIMIT = 40

  def daily_requests_limit
    subscription_plan_free? ? FREE_DAILY_REQUESTS_LIMIT : PAID_DAILY_REQUESTS_LIMIT
  end

  def daily_requests_used
    Message.where(user_id: id, user_type: "user")
           .where(created_at: Time.zone.today.all_day)
           .count
  end

  def requests_remaining
    [ daily_requests_limit - daily_requests_used, 0 ].max
  end

  def quota_exhausted?
    requests_remaining.zero?
  end

  def can_send_request?
    !quota_exhausted?
  end

  # Create or fetch user from OmniAuth hash
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_initialize.tap do |user|
      user.email = auth.info.email.presence || "telegram_#{auth.uid}@example.com"
      user.password = SecureRandom.hex(16) if user.encrypted_password.blank?
      user.save!
    end
  end
end
