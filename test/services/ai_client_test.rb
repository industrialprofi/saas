# frozen_string_literal: true

require "test_helper"

class AiClientTest < ActiveSupport::TestCase
  test "parse_sse_frame parses multiline data correctly" do
    client = Ai::Client.new(base_url: "http://example.com")
    frame = <<~SSE
      event: chunk
      data: {"type":"delta",
      data:  "content":"Привет, ",
      data:  "more":"ok"}

    SSE

    event, data = client.send(:parse_sse_frame, frame)
    assert_equal "chunk", event
    assert_equal "delta", data["type"]
    assert_equal "Привет, ", data["content"]
  end
end
