require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "paid? is true for non-free plans" do
    u1 = users(:one) # free
    u2 = users(:two) # standard
    refute u1.paid?
    assert u2.paid?
  end

  test "from_omniauth creates user with email fallback and random password" do
    auth = OmniAuth::AuthHash.new(
      provider: "telegram",
      uid: "12345",
      info: OmniAuth::AuthHash.new(email: nil)
    )

    user = User.from_omniauth(auth)
    assert user.persisted?
    assert_match /telegram_12345@/i, user.email
    assert user.encrypted_password.present?
  end
end
