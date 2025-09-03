# frozen_string_literal: true

require "application_system_test_case"

class ChatFlowTest < ApplicationSystemTestCase
  # Helpers
  def sign_in_as(user)
    # Devise/Warden helper for system tests
    login_as(user, scope: :user)
  end

  test "paid user posts message and sees AI placeholder via Turbo Stream" do
    user = users(:two) # standard (paid)
    sign_in_as(user)

    visit root_path

    # Ensure chat UI elements are present
    assert_selector "#messages"
    assert_selector "#message_form"

    # Count existing messages before submit
    initial_count = page.all("#messages > *").size

    # Submit a message
    fill_in "message_content", with: "Привет из system-теста"
    within "#message_form" do
      click_on "Отправить"
    end

    # JS-enabled: Turbo Stream updates the page in place without redirect
    assert_current_path root_path

    # Form should be reset via turbo_stream.replace
    assert_field "message_content", with: "", wait: 5

    # Turbo Streams should append two new nodes into #messages
    assert_selector "#messages > *", count: initial_count + 2, wait: 5

    # The last node should be AI bubble, previous one should be user bubble with our text
    last_two = page.all("#messages > *").last(2)
    user_node, ai_node = last_two[0], last_two[1]

    within user_node do
      assert_text "Вы"
      assert_text "Привет из system-теста"
    end

    within ai_node do
      assert_text "AI Ассистент"
    end
  end

  test "free user is blocked and redirected to pricing" do
    user = users(:one) # free
    sign_in_as(user)

    visit root_path

    # Try to submit a message
    fill_in "message_content", with: "Проверка доступа"
    within "#message_form" do
      click_on "Отправить"
    end

    # JS-enabled: Pundit rescue renders turbo_stream append of upgrade note into #messages
    assert_current_path root_path
    assert_selector "#messages", wait: 5
    # Partial shared/_upgrade_note contains CTA text; assert its key content
    assert_text "Подключите", wait: 5
    assert_text "DreamTeamSaaS Plus", wait: 5
  end
end
