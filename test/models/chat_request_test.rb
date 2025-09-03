require "test_helper"

class ChatRequestTest < ActiveSupport::TestCase
  test "validates presence and uniqueness of idempotency_key" do
    user = users(:two)
    cr1 = ChatRequest.create!(user: user, idempotency_key: SecureRandom.uuid, last_user_message_id: 42)
    cr2 = ChatRequest.new(user: user, idempotency_key: cr1.idempotency_key, last_user_message_id: 43)
    refute cr2.valid?
    assert_includes cr2.errors.attribute_names, :idempotency_key
  end

  test "validates presence of last_user_message_id" do
    cr = ChatRequest.new(user: users(:two), idempotency_key: SecureRandom.uuid, last_user_message_id: nil)
    refute cr.valid?
    assert_includes cr.errors.attribute_names, :last_user_message_id
  end
end
