class AddStatusToVolunteers < ActiveRecord::Migration[5.0]
  def change
    add_column :volunteers, :status, :integer, default: 0
  end
end
