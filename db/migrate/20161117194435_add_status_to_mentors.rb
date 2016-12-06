class AddStatusToMentors < ActiveRecord::Migration[5.0]
  def change
    add_column :mentors, :status, :integer, default: 0
  end
end
