# frozen_string_literal: true

# Doorkeeper JWT configuration
# Выдает access token как JWT, подписанный приватным RSA ключом.
# Публичный ключ доступен через JWKS endpoint: /.well-known/jwks.json

require "openssl"

module JwtKeyLoader
  module_function

  # Загружаем приватный ключ из ENV или из файла.
  # В продакшне используйте ENV/credentials. Файл — только для локальной разработки.
  def private_key
    pem = ENV["DOORKEEPER_JWT_PRIVATE_KEY"]
    return OpenSSL::PKey::RSA.new(pem) if pem&.strip&.start_with?("-----BEGIN")

    path = Rails.root.join("config", "jwt", "private.pem")
    return OpenSSL::PKey::RSA.new(File.read(path)) if File.exist?(path)

    raise "Missing DOORKEEPER_JWT_PRIVATE_KEY or config/jwt/private.pem"
  end

  def public_key
    private_key.public_key
  end
end

Doorkeeper::JWT.configure do
  # Алгоритм подписи
  token_payload do |opts|
    # Базовые клеймы JWT
    now = Time.now.to_i
    exp = (now + Doorkeeper.configuration.access_token_expires_in.to_i)

    scopes = Array(opts[:scopes]).map(&:to_s)

    {
      iss: ENV.fetch("JWT_ISSUER", "rails-app"),
      aud: ENV.fetch("JWT_AUDIENCE", "fastapi"),
      iat: now,
      exp: exp,
      scope: scopes.join(" ")
      # Примечание: персональные клеймы пользователя (sub/email/plan)
      # будем добавлять при формировании запроса к FastAPI отдельным JWT,
      # либо через authorization_code flow. Для server-to-server (client_credentials)
      # resource_owner_id отсутствует.
    }
  end

  # Подписываем приватным ключом RSA
  # На первом этапе kid не добавляем; ротация ключей планируется раз в 90 дней
  secret_key { JwtKeyLoader.private_key }
  signing_method :rs256
end
