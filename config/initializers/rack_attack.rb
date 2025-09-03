# frozen_string_literal: true

class Rack::Attack
  # Allow local traffic (healthchecks, dev tools)
  safelist("allow-localhost") do |req|
    [ "127.0.0.1", "::1" ].include?(req.ip)
  end

  # Throttle POST /messages by IP (burst control)
  throttle("messages/ip", limit: 10, period: 60) do |req|
    req.ip if req.post? && req.path == "/messages"
  end

  # Throttle by authenticated user id (if present)
  throttle("messages/user", limit: 20, period: 60) do |req|
    if req.post? && req.path == "/messages"
      # Devise Warden user id from rack env (best-effort)
      user_id = req.env["warden"]&.user&.id rescue nil
      "user:#{user_id}" if user_id
    end
  end

  # Respond with 429 JSON for throttled requests
  self.throttled_responder = lambda do |request|
    headers = {
      "Content-Type" => "application/json; charset=utf-8",
      "Retry-After" => (request.env["rack.attack.match_data"] || {})[:period].to_s
    }
    [ 429, headers, [ { error: "rate_limited", message: "Too many requests" }.to_json ] ]
  end
end
