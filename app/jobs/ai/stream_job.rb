# frozen_string_literal: true

# Streams AI response from FastAPI via SSE and updates AI message progressively.
# Требования: FastAPI SSE endpoint, Doorkeeper JWT, RU-only ответы, таймаут 30s.

class Ai::StreamJob < ApplicationJob
  queue_as :default

  # params: user_id:, last_user_message_id:, chat_request_id:, request_id:, ai_message_id: (optional)
  def perform(user_id:, last_user_message_id:, chat_request_id:, request_id:, ai_message_id: nil)
    user = User.find(user_id)
    chat_request = ChatRequest.find(chat_request_id)

    # Используем существующий плейсхолдер, либо создаем новый (fallback)
    ai_message = ai_message_id ? Message.find(ai_message_id) : Message.create!(user: user, user_type: "ai", content: "")

    # Собираем последние 10 сообщений пользователя (user/ai)
    history = Message.where(user: user).ordered.last(10)
    messages_payload = [
      { role: "system", content: "Отвечай на русском языке." }
    ] + history.map { |m| { role: (m.user_type == "user" ? "user" : "assistant"), content: m.content.to_s } }

    client = Ai::Client.new
    accumulated = +""

    chat_request.update!(status: "running")
    client.stream_chat(
      messages: messages_payload,
      user: { id: user.id, sub: user.id.to_s, email: user.email, plan: user.subscription_plan },
      request_id: request_id,
      idempotency_key: chat_request.idempotency_key
    ) do |event:, data:|
      case event
      when "chunk"
        delta = data["content"].to_s
        next if delta.empty?
        accumulated << delta
        ai_message.update!(content: accumulated)
      when "done"
        chat_request.update!(status: "done")
      when "error"
        chat_request.update!(status: "error", error: data["message"].to_s.presence || "stream error")
        ai_message.update!(content: "Извините, произошла ошибка при генерации ответа.") if ai_message.content.blank?
      end
    end
  rescue StandardError => e
    chat_request&.update!(status: "error", error: e.message) rescue nil
  end
end
