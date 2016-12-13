class RemoveSizeFromVolunteers < ActiveRecord::Migration[5.0]
  def change
    remove_column :volunteers, :size, :string
  end
end
