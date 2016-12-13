class AddOrganizationToMentor < ActiveRecord::Migration[5.0]
  def change
    add_column :mentors, :organization, :string
  end
end
