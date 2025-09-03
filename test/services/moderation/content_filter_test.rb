require "test_helper"

class ModerationContentFilterTest < ActiveSupport::TestCase
  test "raises on blank" do
    assert_raises(ArgumentError) { Moderation::ContentFilter.validate!("") }
  end

  test "raises on blocklisted words" do
    assert_raises(StandardError) { Moderation::ContentFilter.validate!("Это содержит экстремизм") }
  end

  test "raises on email" do
    err = assert_raises(StandardError) { Moderation::ContentFilter.validate!("Почта test@example.com") }
    assert_match /e-mail/i, err.message
  end

  test "raises on phone" do
    err = assert_raises(StandardError) { Moderation::ContentFilter.validate!("Мой телефон +7 999 123-45-67") }
    assert_match /телефон/i, err.message
  end

  test "passes on normal russian text" do
    assert Moderation::ContentFilter.validate!("Привет! Как твои дела сегодня?")
  end
end
