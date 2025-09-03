require "test_helper"

class MessageTest < ActiveSupport::TestCase
  test "validations for user message require content and user_type" do
    msg = Message.new(user_type: "user", content: "Hello")
    assert msg.valid?

    msg2 = Message.new(user_type: "user", content: "")
    refute msg2.valid?
    assert_includes msg2.errors.attribute_names, :content

    # DB may have default user_type; assert inclusion rejects invalid value
    msg3 = Message.new(user_type: "bot", content: "Hi")
    refute msg3.valid?
    assert_includes msg3.errors.attribute_names, :user_type
  end

  test "ai message may have blank content" do
    ai = Message.new(user_type: "ai", content: "")
    assert ai.valid?
  end

  test "scopes ordered and recent" do
    Message.delete_all
    m1 = Message.create!(user_type: "user", content: "1", created_at: 1.hour.ago)
    m2 = Message.create!(user_type: "ai",   content: "2", created_at: 10.minutes.ago)
    m3 = Message.create!(user_type: "user", content: "3", created_at: Time.current)

    assert_equal %w[1 2 3], Message.ordered.pluck(:content)
    assert_equal 2, Message.recent(2).count
    assert_equal %w[1 2], Message.recent(2).pluck(:content)
  end

  test "cleanup_old_messages keeps only last N by created_at asc order" do
    Message.delete_all
    5.times { |i| Message.create!(user_type: (i.even? ? "user" : "ai"), content: "#{i}", created_at: i.minutes.ago) }
    assert_equal 5, Message.count
    Message.cleanup_old_messages(3)
    assert_equal 3, Message.count
    # kept are last 3 by ordered (asc): indices 2,1,0 (2m,1m,now)
    kept_contents = Message.ordered.pluck(:content)
    assert_equal %w[2 1 0], kept_contents
  end
end
