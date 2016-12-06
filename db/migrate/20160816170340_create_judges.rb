class CreateJudges < ActiveRecord::Migration[5.0]
  def change
    create_table :judges do |t|
      t.belongs_to :person, index: true
      t.belongs_to :event, index: true
      t.string :skills, array: true, default: []
   	  t.string :slack_id
    end
  end
end
