class RemovePartFromParticipant < ActiveRecord::Migration[5.0]
  def change
    remove_column :participants, :part, :string
  end
end
