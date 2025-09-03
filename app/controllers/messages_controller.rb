class MessagesController < ApplicationController
  before_action :authenticate_user!, only: :create

  def create
    authorize Message
    @message = Message.new(message_params)
    @message.user_type = "user"
    @message.user = current_user

    # Предварительная модерация: язык (RU only) и контент (блок-листы/PII)
    begin
      Moderation::LanguageFilter.ru_only!(@message.content)
      Moderation::ContentFilter.validate!(@message.content)
    rescue StandardError => e
      @message.errors.add(:content, e.message)
      respond_to do |format|
        format.turbo_stream do
          render status: :unprocessable_entity, turbo_stream: turbo_stream.replace(
            "message_form",
            partial: "messages/form",
            locals: { message: @message }
          )
        end
        format.html { redirect_to root_path, alert: e.message }
      end
      return
    end

    if @message.save
      # Создаем AI-плейсхолдер сразу для лучшего UX
      ai_placeholder = Message.create!(user: current_user, user_type: "ai", content: "")
      @ai_message = ai_placeholder

      # Создаем запись запроса с Idempotency-Key и запускаем стриминг в фоне
      idempotency_key = SecureRandom.uuid
      chat_request = ChatRequest.create!(
        user: current_user,
        idempotency_key: idempotency_key,
        last_user_message_id: @message.id,
        status: "pending"
      )

      Ai::StreamJob.perform_later(
        user_id: current_user.id,
        last_user_message_id: @message.id,
        chat_request_id: chat_request.id,
        request_id: request.request_id,
        ai_message_id: ai_placeholder.id
      )

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to root_path }
      end
    else
      respond_to do |format|
        format.turbo_stream { render status: :unprocessable_entity, turbo_stream: turbo_stream.replace("message_form", partial: "messages/form", locals: { message: @message }) }
        format.html { redirect_to root_path, alert: "Не удалось отправить сообщение." }
      end
    end
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end
end
