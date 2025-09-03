# frozen_string_literal: true

class MessagePolicy < ApplicationPolicy
  def create?
    user.present? && (user.paid? || user.can_send_free_request?)
  end
end
