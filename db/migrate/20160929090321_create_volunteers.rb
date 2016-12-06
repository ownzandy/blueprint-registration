class CreateVolunteers < ActiveRecord::Migration[5.0]
  def change
    create_table :volunteers do |t|
      t.belongs_to :person, index: true
      t.belongs_to :event, index: true
      t.integer :hours, default: 0
      t.string :size
      t.string :times, array: true, default: []
      t.string :custom, array: true, default: []
      t.string :slack_id
      t.timestamps
    end
  end
end
