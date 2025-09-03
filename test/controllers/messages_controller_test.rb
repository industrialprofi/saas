require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  test "paid user can create message" do
    # user with standard plan from fixtures
    sign_in users(:two)

    assert_difference "Message.count", 2 do
      # user message + AI placeholder (streamed later)
      post messages_path, params: { message: { content: "Привет, как дела?" } }
    end

    assert_redirected_to root_path
  end

  test "guest is redirected to sign in" do
    assert_no_difference "Message.count" do
      post messages_path, params: { message: { content: "Привет" } }
    end
    assert_response :redirect
    assert_match /sign_in|sign-up|users\/sign_in/, @response.redirect_url
  end

  test "free user is redirected to pricing by Pundit rescue" do
    sign_in users(:one) # free
    assert_no_difference "Message.count" do
      post messages_path, params: { message: { content: "Привет" } }
    end
    assert_redirected_to pricing_path
    assert_equal "Доступ доступен только по платной подписке.", flash[:alert]
  end

  test "moderation error returns alert on html" do
    sign_in users(:two) # paid
    # ContentFilter rejects phone numbers; digits don't affect RU ratio
    assert_no_difference "Message.count" do
      post messages_path, params: { message: { content: "Мой номер +7 999 123-45-67, перезвони" } }
    end
    # Controller handles HTML fallback with redirect to root
    assert_redirected_to root_path
    assert_equal "Пожалуйста, не указывайте телефонные номера.", flash[:alert]
  end
end
