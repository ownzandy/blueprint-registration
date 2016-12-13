class AddDepartmentToMentor < ActiveRecord::Migration[5.0]
  def change
    add_column :mentors, :department, :string
  end
end
