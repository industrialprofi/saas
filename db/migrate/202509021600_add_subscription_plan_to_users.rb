class AddSubscriptionPlanToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :subscription_plan, :integer, null: false, default: 0
    add_index :users, :subscription_plan
  end
end
