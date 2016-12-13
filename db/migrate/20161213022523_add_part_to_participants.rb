class AddPartToParticipants < ActiveRecord::Migration[5.0]
  def change
    add_column :participants, :part, :string, array: true, default: []
  end
end
