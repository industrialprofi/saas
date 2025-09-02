# frozen_string_literal: true
module Moderation
  # Content moderation with simple blocklists and PII detection
  # На первом этапе: простые проверки. Позже можно вынести в FastAPI и/или усложнить.
  class ContentFilter
    BLOCKLIST = [
      # Добавьте нежелательные слова/темы (примерные значения)
      'запрещенное', 'экстремизм', 'ненависть'
    ].freeze

    EMAIL_REGEX = /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/i.freeze
    PHONE_REGEX = /(?:\+?\d[\s-]?){7,14}/.freeze

    def self.validate!(text)
      raise ArgumentError, 'text is blank' if text.to_s.strip.empty?

      normalized = text.downcase

      if BLOCKLIST.any? { |w| normalized.include?(w) }
        raise StandardError, 'Сообщение содержит запрещенный контент.'
      end

      if EMAIL_REGEX.match?(text)
        raise StandardError, 'Пожалуйста, не указывайте e-mail адреса.'
      end

      if PHONE_REGEX.match?(text)
        raise StandardError, 'Пожалуйста, не указывайте телефонные номера.'
      end

      true
    end
  end
end
