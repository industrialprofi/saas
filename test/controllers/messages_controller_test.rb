require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  test "paid user can create message" do
    # user with standard plan from fixtures
    sign_in users(:two)

    assert_difference "Message.count", 2 do
      # user message + AI response
      post messages_path, params: { message: { content: "Hello from test" } }
    end

    assert_redirected_to root_path
  end
end
