# frozen_string_literal: true
module Moderation
  # Simple Russian language detector (heuristic)
  # В продакшне рекомендую заменить на библиотеку или FastAPI модуль.
  class LanguageFilter
    # Проверяем, что текст на русском языке.
    # Эвристика: достаточная доля кириллицы и отсутствие принудительных латинских слов.
    def self.ru_only!(text)
      raise ArgumentError, 'text is blank' if text.to_s.strip.empty?

      # Подсчитываем долю кириллических символов
      total = text.scan(/[A-Za-zА-Яа-яЁё]/).size
      cyr   = text.scan(/[А-Яа-яЁё]/).size
      ratio = total.positive? ? (cyr.to_f / total) : 0.0

      # Дополнительные эвристики: частые русские слова
      common_ru = %w[и в не на я что тот быть с он как это по а то всё она так его]
      ru_hits = common_ru.count { |w| text.downcase.include?(" #{w} ") }

      # Порог: ≥ 0.6 кириллицы или ≥ 2 общих русских слова
      ok = ratio >= 0.6 || ru_hits >= 2
      raise StandardError, 'Пожалуйста, используйте русский язык.' unless ok

      true
    end
  end
end
