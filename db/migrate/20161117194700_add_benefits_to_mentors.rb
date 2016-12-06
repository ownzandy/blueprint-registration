class AddBenefitsToMentors < ActiveRecord::Migration[5.0]
  def change
    add_column :mentors, :benefits, :string, array: true, default: []
  end
end
