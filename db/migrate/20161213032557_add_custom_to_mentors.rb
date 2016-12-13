class AddCustomToMentors < ActiveRecord::Migration[5.0]
  def change
    add_column :mentors, :custom, :string, array: true, default: []
  end
end
