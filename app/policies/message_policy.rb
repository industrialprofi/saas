# frozen_string_literal: true

class MessagePolicy < ApplicationPolicy
  def create?
    user.present? && user.paid?
  end
end
