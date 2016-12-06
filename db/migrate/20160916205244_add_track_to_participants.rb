class AddTrackToParticipants < ActiveRecord::Migration[5.0]
  def change
    add_column :participants, :track, :string
  end
end
