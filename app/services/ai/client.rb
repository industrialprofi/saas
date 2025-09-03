# frozen_string_literal: true

# Simple SSE client for FastAPI chat streaming
# Отвечает за открытие стриминга, передачу контекста и разбор SSE событий.

require "faraday"
require "json"

module Ai
  class Client
    DEFAULT_TIMEOUT = 30 # seconds

    def initialize(base_url: ENV.fetch("FASTAPI_BASE_URL", nil), timeout: DEFAULT_TIMEOUT)
      raise ArgumentError, "FASTAPI_BASE_URL is not set" if base_url.to_s.empty?

      @base_url = base_url.chomp("/")
      @timeout = timeout
    end

    # Opens SSE stream and yields events as hashes: { event: 'chunk'|'done'|'error', data: {...} }
    # Params:
    # - messages: array of hashes [{ role: 'system'|'user'|'assistant', content: '...' }]
    # - user: { id:, sub:, email:, plan: }
    # - request_id: String
    # - idempotency_key: String (UUID)
    # - scope: String (space-delimited scopes), default 'ai:chat'
    def stream_chat(messages:, user:, request_id:, idempotency_key:, scope: "ai:chat")
      path = "/v1/chat/stream"
      jwt_aud = ENV.fetch("FASTAPI_AUD", "fastapi")
      token = Ai::JwtIssuer.issue(sub: user[:sub] || user[:id], aud: jwt_aud, request_id: request_id)

      attempts = 0
      begin
        attempts += 1

        conn = Faraday.new(url: @base_url) do |f|
          f.request :json
          f.options.timeout = @timeout
          f.options.open_timeout = [7, @timeout].min
          # default adapter (net_http) supports on_data
        end

        buffer = +""
        response = conn.post(path) do |req|
          req.headers["Accept"] = "text/event-stream"
          req.headers["Content-Type"] = "application/json"
          req.headers["X-Request-ID"] = request_id.to_s
          req.headers["Idempotency-Key"] = idempotency_key.to_s
          req.headers["Accept-Language"] = "ru"
          req.headers["Authorization"] = "Bearer #{token}"
          req.options.on_data = proc do |chunk, _overall_received_bytes|
            buffer << chunk
            while (sep = buffer.index("\n\n"))
              frame = buffer.slice!(0..sep + 1)
              event, data = parse_sse_frame(frame)
              next unless event
              yield(event: event, data: data)
            end
          end
          req.body = {
            messages: messages,
            user: user,
            params: {
              temperature: ENV.fetch("AI_TEMPERATURE", 0.7).to_f,
              max_tokens: ENV.fetch("AI_MAX_TOKENS", 500).to_i
            }
          }
        end

        unless response.success?
          err = begin
            JSON.parse(response.body)
          rescue StandardError
            { "message" => response.reason_phrase }
          end
          yield(event: "error", data: { "code" => response.status, "message" => err["message"] })
        end
      rescue Faraday::TimeoutError
        raise if attempts > 2
        sleep(0.5 * attempts)
        retry
      rescue Faraday::ConnectionFailed, Faraday::SSLError => e
        raise if attempts > 2
        sleep(0.5 * attempts)
        retry
      end
    rescue Faraday::TimeoutError
      yield(event: "error", data: { "code" => "timeout", "message" => "Превышен таймаут стрима (30s)." })
    rescue StandardError => e
      yield(event: "error", data: { "code" => "client_error", "message" => e.message })
    end

    private

    # Removed Doorkeeper client credentials issuance; using JWT instead for internal FastAPI auth.

    # Parse SSE frame lines: event: <name>, data: <json>
    def parse_sse_frame(frame)
      event = nil
      data_lines = []
      frame.each_line do |raw|
        line = raw.chomp
        next if line.empty? || line.start_with?(":")
        if line.start_with?("event:")
          event = line.sub("event:", "").strip
        elsif line.start_with?("data:")
          data_lines << line.sub("data:", "").lstrip
        end
      end

      data = begin
        payload = data_lines.join("\n")
        payload.empty? ? nil : JSON.parse(payload)
      rescue JSON::ParserError
        nil
      end

      [ event, data ]
    end
  end
end
