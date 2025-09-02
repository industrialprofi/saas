class HistoryController < ApplicationController
  before_action :authenticate_user!

  def index
    authorize :history, :index?

    @query = params[:q]
    @messages = Message
                  .where(user_id: current_user.id)
                  .from_user
                  .last_30_days
                  .search(@query)
                  .reorder(created_at: :desc)
  end
end
