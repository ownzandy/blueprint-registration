class AddTrackToMentors < ActiveRecord::Migration[5.0]
  def change
    add_column :mentors, :track, :string
  end
end
