class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:telegram]

  enum :subscription_plan, { free: 0, standard: 1 }, prefix: true, default: :free

  def paid?
    !subscription_plan_free?
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
