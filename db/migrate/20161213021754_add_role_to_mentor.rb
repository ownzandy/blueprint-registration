class AddRoleToMentor < ActiveRecord::Migration[5.0]
  def change
    add_column :mentors, :role, :string
  end
end
