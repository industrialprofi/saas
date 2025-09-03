require "test_helper"

class ModerationLanguageFilterTest < ActiveSupport::TestCase
  test "raises on blank" do
    assert_raises(ArgumentError) { Moderation::LanguageFilter.ru_only!("") }
  end

  test "accepts russian text" do
    assert Moderation::LanguageFilter.ru_only!("Привет, как твои дела сегодня?")
  end

  test "rejects mostly english text" do
    err = assert_raises(StandardError) { Moderation::LanguageFilter.ru_only!("Hello, how are you today?") }
    assert_match /русский/i, err.message
  end

  test "accepts due to common russian words" do
    assert Moderation::LanguageFilter.ru_only!("Это он и она по делам")
  end
end
