# frozen_string_literal: true

class HistoryPolicy < ApplicationPolicy
  def index?
    user.present?
  end
end
