class CreateProjects < ActiveRecord::Migration[5.0]
  def change
    create_table :projects do |t|
   	  t.belongs_to :team, index: true
   	  t.string :title
   	  t.string :api_prize, array: true, default: []
   	  t.string :website_url
   	  t.string :submission_url
   	  t.timestamps
    end
  end
end
