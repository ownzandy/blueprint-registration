class CreateSponsors < ActiveRecord::Migration[5.0]
  def change
  	 create_table :sponsors do |t|
  	  t.integer :organization_id
  	  t.belongs_to :event, index: true
      t.integer :sponsorship_tier
      t.timestamps 
    end
  end
end
