class AddDepartmentToSpeaker < ActiveRecord::Migration[5.0]
  def change
    add_column :speakers, :department, :string
  end
end
