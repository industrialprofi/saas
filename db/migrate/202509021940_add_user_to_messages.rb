class AddUserToMessages < ActiveRecord::Migration[8.0]
  def change
    add_reference :messages, :user, foreign_key: true, index: true, null: true
    add_index :messages, :created_at
  end
end
