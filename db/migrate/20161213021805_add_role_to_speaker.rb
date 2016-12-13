class AddRoleToSpeaker < ActiveRecord::Migration[5.0]
  def change
    add_column :speakers, :role, :string
  end
end
