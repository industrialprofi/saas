# frozen_string_literal: true

# Simple SSE client for FastAPI chat streaming
# Отвечает за открытие стриминга, передачу контекста и разбор SSE событий.

require "net/http"
require "uri"
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
      uri = URI.parse("#{@base_url}/v1/chat/stream")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = @timeout
      http.read_timeout = @timeout

      req = Net::HTTP::Post.new(uri.request_uri)
      req["Accept"] = "text/event-stream"
      req["Content-Type"] = "application/json"
      req["X-Request-ID"] = request_id.to_s
      req["Idempotency-Key"] = idempotency_key.to_s
      req["Accept-Language"] = "ru"
      req["Authorization"] = "Bearer #{issue_client_credentials_token(scope: scope)}"

      body = {
        messages: messages,
        user: user,
        params: { temperature: 0.7, max_tokens: 500 }
      }
      req.body = JSON.dump(body)

      http.request(req) do |res|
        # Валидация статуса до начала стрима
        unless res.is_a?(Net::HTTPSuccess)
          # Пробуем распарсить ошибку
          err = begin
            JSON.parse(res.body)
          rescue StandardError
            { "message" => res.message }
          end
          yield(event: "error", data: { "code" => res.code, "message" => err["message"] })
          next
        end

        buffer = +""
        res.read_body do |chunk|
          buffer << chunk

          # SSE фреймы разделены двойным переводом строки
          while (idx = buffer.index("\n\n"))
            frame = buffer.slice!(0..idx)
            event, data = parse_sse_frame(frame)
            next if event.nil? && data.nil?

            yield(event: event, data: data)
          end
        end
      end
    rescue Net::OpenTimeout, Net::ReadTimeout
      yield(event: "error", data: { "code" => "timeout", "message" => "Превышен таймаут стрима (30s)." })
    rescue StandardError => e
      yield(event: "error", data: { "code" => "client_error", "message" => e.message })
    end

    private

    # Генерируем OAuth токен по client_credentials через Doorkeeper
    # Примечание: для простоты используем Doorkeeper::AccessToken без сети (локально)
    def issue_client_credentials_token(scope: "ai:chat")
      app = Doorkeeper::Application.find_by(name: "fastapi-internal") || Doorkeeper::Application.first
      raise "Create a Doorkeeper application for FastAPI (e.g., name: fastapi-internal)" unless app

      token = Doorkeeper::AccessToken.find_or_create_for(
        application: app,
        resource_owner: nil,
        scopes: scope,
        expires_in: Doorkeeper.configuration.access_token_expires_in,
        use_refresh_token: false
      )
      token.token
    end

    # Parse SSE frame lines: event: <name>, data: <json>
    def parse_sse_frame(frame)
      event = nil
      data_json = nil
      frame.each_line do |line|
        line = line.strip
        next if line.empty? || line.start_with?(":")
        if line.start_with?("event:")
          event = line.sub("event:", "").strip
        elsif line.start_with?("data:")
          data_json = line.sub("data:", "").strip
        end
      end

      data = begin
        data_json ? JSON.parse(data_json) : nil
      rescue StandardError
        nil
      end

      [ event, data ]
    end
  end
end
