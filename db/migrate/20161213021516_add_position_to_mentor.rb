class AddPositionToMentor < ActiveRecord::Migration[5.0]
  def change
    add_column :mentors, :position, :string
  end
end
