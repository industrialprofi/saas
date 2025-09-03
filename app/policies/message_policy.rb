# frozen_string_literal: true

class MessagePolicy < ApplicationPolicy
  def create?
    user.present? && user.can_send_request?
  end
end
