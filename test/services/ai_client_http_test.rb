# frozen_string_literal: true

require "test_helper"

class AiClientHttpTest < ActiveSupport::TestCase
  def build_client
    Ai::Client.new(base_url: "http://example.com", timeout: 1)
  end

  test "success: streams chunk and done" do
    sse = [
      "event: chunk\n",
      "data: {\"content\":\"Привет\"}\n\n",
      "event: done\n",
      "data: {}\n\n"
    ].join

    stub_request(:post, "http://example.com/v1/chat/stream")
      .to_return(status: 200, body: sse, headers: { "Content-Type" => "text/event-stream" })

    client = build_client
    events = []

    # Переопределяем метод токена на инстансе, чтобы не зависеть от Doorkeeper
    client.define_singleton_method(:issue_client_credentials_token) { |**| "test-token" }

    client.stream_chat(
      messages: [{ role: "user", content: "hi" }],
      user: { id: 1, sub: "1", email: "u@example.com", plan: "standard" },
      request_id: "req-1",
      idempotency_key: "idem-1"
    ) do |event:, data:|
      events << [event, data]
    end

    # Проверяем, что пришёл chunk с текстом и затем done
    assert_equal [
      ["chunk", { "content" => "Привет" }],
      ["done", {}]
    ], events

    assert_requested :post, "http://example.com/v1/chat/stream", times: 1
  end

  test "5xx: yields error event with code and message" do
    stub_request(:post, "http://example.com/v1/chat/stream")
      .to_return(status: 500, body: '{"message":"server boom"}', headers: { "Content-Type" => "application/json" })

    client = build_client
    events = []

    client.define_singleton_method(:issue_client_credentials_token) { |**| "test-token" }

    client.stream_chat(
      messages: [{ role: "user", content: "hi" }],
      user: { id: 1, sub: "1", email: "u@example.com", plan: "standard" },
      request_id: "req-2",
      idempotency_key: "idem-2"
    ) do |event:, data:|
      events << [event, data]
    end

    assert_equal 1, events.size
    event, data = events.first
    assert_equal "error", event
    assert_equal "500", data["code"]
    assert_match /server boom/i, data["message"].to_s
    assert_requested :post, "http://example.com/v1/chat/stream", times: 1
  end

  test "timeouts: retries then yields timeout error" do
    # Симулируем таймаут (WebMock будет бросать Net::ReadTimeout)
    stub_request(:post, "http://example.com/v1/chat/stream").to_timeout

    client = build_client
    events = []

    client.define_singleton_method(:issue_client_credentials_token) { |**| "test-token" }

    client.stream_chat(
      messages: [{ role: "user", content: "hi" }],
      user: { id: 1, sub: "1", email: "u@example.com", plan: "standard" },
      request_id: "req-3",
      idempotency_key: "idem-3"
    ) do |event:, data:|
      events << [event, data]
    end

    # Ожидаем единственное событие error с кодом timeout
    assert_equal 1, events.size
    event, data = events.first
    assert_equal "error", event
    assert_equal "timeout", data["code"]

    # Три попытки (1 + 2 ретрая)
    assert_requested :post, "http://example.com/v1/chat/stream", times: 3
  end
end
