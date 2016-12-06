class AddBenefitsToVolunteers < ActiveRecord::Migration[5.0]
  def change
    add_column :volunteers, :benefits, :string, array: true, default: []
  end
end
