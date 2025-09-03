class AddIndexMessagesOnUserIdCreatedAt < ActiveRecord::Migration[7.1]
  def change
    add_index :messages, [:user_id, :created_at]
  end
end
