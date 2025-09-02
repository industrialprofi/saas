# frozen_string_literal: true

class ChatRequest < ApplicationRecord
  belongs_to :user

  validates :idempotency_key, presence: true, uniqueness: true
  validates :last_user_message_id, presence: true
end
