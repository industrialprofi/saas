require "test_helper"

class MessagePolicyTest < ActiveSupport::TestCase
  def policy(user)
    MessagePolicy.new(user, Message)
  end

  test "guest cannot create" do
    refute policy(nil).create?
  end

  test "free user cannot create" do
    refute policy(users(:one)).create?
  end

  test "paid user can create" do
    assert policy(users(:two)).create?
  end
end
