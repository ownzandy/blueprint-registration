class CreateSpeakers < ActiveRecord::Migration[5.0]
  def change
  	 create_table :speakers do |t|
  	  t.belongs_to :person, index: true
  	  t.belongs_to :event, index: true
      t.string :topic, array: true, default: []
      t.string :description, array: true, default: []
      t.datetime :date, array: true, default: []
      t.string :slack_id
      t.timestamps 
    end
  end
end
