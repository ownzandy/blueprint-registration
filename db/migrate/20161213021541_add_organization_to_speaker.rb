class AddOrganizationToSpeaker < ActiveRecord::Migration[5.0]
  def change
    add_column :speakers, :organization, :string
  end
end
