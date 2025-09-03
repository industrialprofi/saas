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

  # Daily free requests quota
  FREE_DAILY_REQUESTS_LIMIT = 3

  def daily_free_requests_limit
    FREE_DAILY_REQUESTS_LIMIT
  end

  def daily_free_requests_used
    return 0 unless subscription_plan_free?

    Message.where(user_id: id, user_type: "user")
           .where(created_at: Time.zone.today.all_day)
           .count
  end

  def free_requests_remaining
    return 0 unless subscription_plan_free?

    [ daily_free_requests_limit - daily_free_requests_used, 0 ].max
  end

  def can_send_free_request?
    subscription_plan_free? && free_requests_remaining.positive?
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
