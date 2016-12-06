class CreateOrganizers < ActiveRecord::Migration[5.0]
  def change
    create_table :organizers do |t|
      t.belongs_to :person, index: true
      t.belongs_to :event, index: true
      t.string :slack_id
      t.timestamps
    end
  end
end
