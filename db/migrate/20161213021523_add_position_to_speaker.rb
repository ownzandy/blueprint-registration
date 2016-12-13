class AddPositionToSpeaker < ActiveRecord::Migration[5.0]
  def change
    add_column :speakers, :position, :string
  end
end
