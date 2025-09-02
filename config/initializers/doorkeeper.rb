# frozen_string_literal: true
# Configures Doorkeeper (OAuth 2.0 provider)
# Внимание: после добавления, выполните миграции doorkeeper и создайте OAuth приложение для server-to-server.

Doorkeeper.configure do
  # ActiveRecord ORM (по умолчанию)
  orm :active_record

  # Разрешенные grant flows. Для server-to-server нам нужен client_credentials.
  grant_flows %w[client_credentials authorization_code]

  # Настраиваем доступные скоупы для токенов
  default_scopes  :"project:read"
  optional_scopes :"ai:chat", :"ai:moderate", :"project:create"

  # Разрешаем выдачу клиентских токенов без resource owner (machine-to-machine)
  allow_blank_redirect_uri true

  # Опционально: ограничить приложения только конфиденциальными клиентами
  # confidential_applications true

  # Укорачиваем время жизни access token (минимизируем риск)
  access_token_expires_in 5.minutes

  # Refresh токены не используем для server-to-server коротких вызовов
  use_refresh_token false

  # Ограничение повторной выдачи одного и того же токена для одного ключа идемпотентности реализуем приложением.

  # Включаем Doorkeeper JWT токены (см. doorkeeper-jwt initializer)
  access_token_generator '::Doorkeeper::JWT'

  # Валидация скоупов
  enforce_configured_scopes

  # Параметры конфиденциальности журнала
  # hash_token_secrets true
end
