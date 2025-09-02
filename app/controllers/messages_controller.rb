class MessagesController < ApplicationController
  before_action :authenticate_user!, only: :create

  def create
    authorize Message
    @message = Message.new(message_params)
    @message.user_type = "user"
    @message.user = current_user

    if @message.save
      # Создаем ответ от AI
      ai_response = Message.create(
        content: generate_ai_response(@message.content),
        user_type: "ai",
        user: current_user
      )

      # Очищаем старые сообщения, оставляя только последние 100
      Message.cleanup_old_messages(100)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to root_path }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("message_form", partial: "messages/form", locals: { message: @message }) }
        format.html { redirect_to root_path, alert: "Не удалось отправить сообщение." }
      end
    end
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end

  def generate_ai_response(user_message)
    # Простой механизм генерации ответов
    # В будущем можно заменить на интеграцию с реальным AI API

    # Короткие вопросы получают стандартные ответы
    if user_message.length < 10
      return "Пожалуйста, уточните ваш вопрос. Я хотел бы помочь вам наилучшим образом."
    end

    # Простой механизм подбора ответа по ключевым словам
    keywords = {
      /\bпривет\b|здравствуй\b|добрый день\b/i => "Привет! Очень приятно познакомиться. Чем я могу вам помочь?",
      /\bсервис\b|возможност\b|функци\b/i => "Наш сервис предлагает широкий спектр возможностей: ответы на вопросы, помощь с задачами, переводы и многое другое.",
      /\bпомощ\b|помоч\b|помоги\b/i => "Я с радостью помогу вам. Пожалуйста, опишите вашу задачу подробнее.",
      /\bспасиб\b|благодар\b/i => "Всегда рад помочь! Есть ли ещё что-то, с чем я могу вам помочь?"
    }

    # Проверяем ключевые слова в сообщении
    keywords.each do |pattern, response|
      return response if user_message.match?(pattern)
    end

    # Стандартный ответ, если не найдено совпадений
    "Спасибо за ваше сообщение! Я обработал ваш запрос и готов помочь вам с этим вопросом."
  end
end
