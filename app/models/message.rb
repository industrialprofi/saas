class Message < ApplicationRecord
  belongs_to :user, optional: true
  # Для AI-плейсхолдера допускаем пустой контент, чтобы обновлять его по стриму
  validates :content, presence: true, unless: -> { user_type == "ai" }
  validates :user_type, presence: true, inclusion: { in: [ "user", "ai" ] }

  # Броадкаст сообщений через Turbo Streams
  after_create_commit -> { broadcast_append_to "messages" }
  after_update_commit -> { broadcast_replace_to "messages" }

  # Персонифицированные стримы: [user, :messages]
  after_create_commit -> { broadcast_append_to [ user || :guest, :messages ] }
  after_update_commit -> { broadcast_replace_to [ user || :guest, :messages ] }

  # Сортировка по времени создания (новые внизу)
  scope :ordered, -> { order(created_at: :asc) }

  # Последние N сообщений
  scope :recent, ->(limit = 20) { ordered.limit(limit) }

  # За последние 30 дней (по убыванию)
  scope :last_30_days, -> { where("created_at >= ?", 30.days.ago).order(created_at: :desc) }

  # Поиск по подстроке (ILIKE)
  scope :search, ->(q) { q.present? ? where("content ILIKE ?", "%#{sanitize_sql_like(q)}%") : all }

  # Сообщения от пользователя
  scope :from_user, -> { where(user_type: "user") }

  # Сообщения от AI
  scope :from_ai, -> { where(user_type: "ai") }

  # Очистка старых сообщений
  def self.cleanup_old_messages(keep_count = 100)
    return unless count > keep_count

    ids_to_keep = ordered.last(keep_count).pluck(:id)
    where.not(id: ids_to_keep).delete_all
  end
end
