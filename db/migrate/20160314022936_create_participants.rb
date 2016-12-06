class CreateParticipants < ActiveRecord::Migration[5.0]
  def change
  	create_table :participants do |t|
      t.belongs_to :person, index: true
      t.belongs_to :event, index: true
      t.belongs_to :team, index: true
      t.integer :status, default: 0
      t.integer :graduation_year
      t.integer :over_eighteen
      t.integer :attending
      t.string :major
      t.string :school
      t.string :website
      t.string :resume
      t.string :github
      t.string :travel
      t.string :portfolio
      t.string :skills, array: true, default: []
      t.string :custom, array: true, default: []
      t.string :slack_id
      t.timestamps
    end
  end
end
