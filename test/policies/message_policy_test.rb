require "test_helper"

class MessagePolicyTest < ActiveSupport::TestCase
  def policy(user)
    MessagePolicy.new(user, Message)
  end

  test "guest cannot create" do
    refute policy(nil).create?
  end

  test "free user within quota can create" do
    user = users(:one)
    assert policy(user).create?
  end

  test "free user over quota cannot create" do
    user = users(:one)
    3.times { Message.create!(user: user, user_type: "user", content: "x") }
    refute policy(user).create?
  end

  test "paid user can create" do
    assert policy(users(:two)).create?
  end
end
