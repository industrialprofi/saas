module MessagesHelper
  def quota_label(user)
    return "" unless user

    remaining = user.requests_remaining
    limit = user.daily_requests_limit
    "Запросы: #{remaining}/#{limit}"
  end

  def quota_text_classes(user)
    base = "mt-2 text-sm"
    return base unless user

    exhausted = user.quota_exhausted?
    color = exhausted ? "text-red-600" : "text-gray-600 dark:text-gray-300"
    "#{base} #{color}"
  end
end
