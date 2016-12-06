class AddBenefitsToParticipants < ActiveRecord::Migration[5.0]
  def change
    add_column :participants, :benefits, :string, array: true, default: []
  end
end
