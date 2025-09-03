module MessagesHelper
  def free_quota_label(user)
    return '' unless user&.subscription_plan_free?

    used = user.daily_free_requests_used
    limit = user.daily_free_requests_limit
    "Запросы: #{used}/#{limit}"
  end
end
