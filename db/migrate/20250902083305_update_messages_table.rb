class UpdateMessagesTable < ActiveRecord::Migration[8.0]
  def change
    # Удаляем старые колонки
    remove_column :messages, :user_input, :text
    remove_column :messages, :ai_response, :text
    
    # Добавляем новые колонки
    add_column :messages, :content, :text, null: false
    add_column :messages, :user_type, :string, null: false, default: 'user'
    
    # Добавляем индекс для быстрого поиска по типу пользователя
    add_index :messages, :user_type
  end
end
