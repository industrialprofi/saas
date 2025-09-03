# frozen_string_literal: true

require "jwt"
require "openssl"
require "digest"

module Ai
  # Issues short-lived JWT for FastAPI authorization
  class JwtIssuer
    DEFAULT_TTL = 60 # seconds

    def self.issue(sub:, aud:, request_id:, ttl: DEFAULT_TTL)
      private_key_path = Rails.root.join('config/jwt/private.pem')
      private_pem = File.read(private_key_path)
      key = OpenSSL::PKey::RSA.new(private_pem)
      now = Time.now.to_i

      payload = {
        iss: app_issuer,
        sub: sub.to_s,
        aud: aud,
        iat: now,
        exp: now + ttl,
        jti: request_id
      }

      headers = { kid: key_id(key) }

      JWT.encode(payload, key, 'RS256', headers)
    end

    def self.app_issuer
      ENV.fetch('JWT_ISS', 'rails-saas')
    end

    def self.key_id(key)
      pub = key.public_key.to_pem
      Digest::SHA1.hexdigest(pub)[0, 16]
    end
  end
end
