# frozen_string_literal: true

class CreateChatRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :chat_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.string :idempotency_key, null: false
      t.bigint :last_user_message_id, null: false
      t.string :status, null: false, default: 'pending'
      t.string :error
      t.timestamps
    end

    add_index :chat_requests, :idempotency_key, unique: true
  end
end
