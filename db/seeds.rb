# Seeds for development/test. Idempotent.
# Load with: bin/rails db:seed

require 'securerandom'

ActiveRecord::Base.transaction do
  puts 'Seeding users...'

  users = [
    { email: 'user1@example.com', password: 'password123' },
    { email: 'user2@example.com', password: 'password123' },
    { email: 'user3@example.com', password: 'password123' },
  ]

  users.each do |attrs|
    u = User.find_or_initialize_by(email: attrs[:email])
    u.password = attrs[:password] if attrs[:password].present?
    u.save!
    # Make the second user a paid user for testing
    u.update!(subscription_plan: :standard) if u.email == 'user2@example.com' && u.subscription_plan_free?
    puts "  ✓ #{u.email}"
  end

  telegram_users = [
    { email: 'telegram_1001@example.com', provider: 'telegram', uid: '1001' },
    { email: 'telegram_1002@example.com', provider: 'telegram', uid: '1002' },
  ]

  telegram_users.each do |attrs|
    u = User.find_or_initialize_by(email: attrs[:email])
    u.provider = attrs[:provider]
    u.uid = attrs[:uid]
    u.password = SecureRandom.hex(12) if u.encrypted_password.blank?
    u.save!
    puts "  ✓ #{u.email} (#{u.provider}:#{u.uid})"
  end

  puts 'Done.'
end
