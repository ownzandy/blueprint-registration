class CreateTeams < ActiveRecord::Migration[5.0]
  def change
    create_table :teams do |t|
   	  t.belongs_to :event, index: true
   	  t.integer :team_leader
    end
  end
end
