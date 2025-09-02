# frozen_string_literal: true
# Публикует JWKS (JSON Web Key Set) с публичным RSA ключом для верификации JWT
# FastAPI будет забирать ключ по /.well-known/jwks.json

require 'base64'

class OAuth::JwksController < ApplicationController
  # JWKS должен быть публичным и кэшируемым; аутентификация не требуется
  skip_before_action :verify_authenticity_token

  def show
    pub = JwtKeyLoader.public_key
    jwk = rsa_to_jwk(pub)

    # Рекомендуется кэшировать ответ на сторону CDN/прокси
    expires_in 10.minutes, public: true

    render json: { keys: [jwk] }
  end

  private

  # Преобразование OpenSSL::PKey::RSA публичного ключа в JWK без kid (пока без ротации)
  def rsa_to_jwk(public_key)
    # n и e должны быть в base64url без паддинга
    n = base64url_uint(public_key.n)
    e = base64url_uint(public_key.e)

    {
      kty: 'RSA',
      alg: 'RS256',
      use: 'sig',
      n: n,
      e: e
      # kid: добавим при внедрении ротации ключей
    }
  end

  def base64url_uint(int)
    s = int.to_s(2)
    s = '0' + s if s.length.odd?
    hex = [s].pack('B*').unpack1('H*')
    der = [hex].pack('H*')
    base64url(der)
  end

  def base64url(bin)
    Base64.urlsafe_encode64(bin).delete('=')
  end
end
