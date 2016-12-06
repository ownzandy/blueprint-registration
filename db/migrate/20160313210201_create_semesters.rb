class CreateSemesters < ActiveRecord::Migration[5.0]
  def change
    create_table :semesters do |t|
      t.integer :season
      t.integer :year
      t.timestamps 
    end
  end
end
