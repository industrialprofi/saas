# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class AiStreamJobTest < ActiveSupport::TestCase
  test "updates ai message content from chunks and marks request done" do
    user = users(:two)
    # history
    Message.create!(user: user, user_type: "user", content: "Привет")

    ai_message = Message.create!(user: user, user_type: "ai", content: "")
    chat_request = ChatRequest.create!(user: user, idempotency_key: SecureRandom.uuid, last_user_message_id: 123, status: "pending")

    # Stub Ai::Client to yield chunks and done
    fake_client = Minitest::Mock.new
    fake_client.expect(:stream_chat, nil) do |messages:, user:, request_id:, idempotency_key:, scope: "ai:chat", &blk|
      blk.call(event: "chunk", data: { "content" => "Привет, " })
      blk.call(event: "chunk", data: { "content" => "мир!" })
      blk.call(event: "done", data: {})
      true
    end

    Ai::Client.stub :new, fake_client do
      Ai::StreamJob.perform_now(user_id: user.id, last_user_message_id: 1, chat_request_id: chat_request.id, request_id: "req-1", ai_message_id: ai_message.id)
    end

    assert_equal " Привет, мир!", ai_message.reload.content
    assert_equal "done", chat_request.reload.status
  end

  test "on error event marks request error and sets fallback text" do
    user = users(:two)
    ai_message = Message.create!(user: user, user_type: "ai", content: "")
    chat_request = ChatRequest.create!(user: user, idempotency_key: SecureRandom.uuid, last_user_message_id: 123, status: "pending")

    fake_client = Minitest::Mock.new
    fake_client.expect(:stream_chat, nil) do |messages:, user:, request_id:, idempotency_key:, scope: "ai:chat", &blk|
      blk.call(event: "error", data: { "message" => "boom" })
      true
    end

    Ai::Client.stub :new, fake_client do
      Ai::StreamJob.perform_now(user_id: user.id, last_user_message_id: 1, chat_request_id: chat_request.id, request_id: "req-2", ai_message_id: ai_message.id)
    end

    assert_equal "error", chat_request.reload.status
    assert_match /ошибка/i, ai_message.reload.content
  end
end
