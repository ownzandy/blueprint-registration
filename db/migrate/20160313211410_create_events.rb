class CreateEvents < ActiveRecord::Migration[5.0]
  def change  
    create_table :events do |t|
      t.belongs_to :semester, index: true
      t.integer :active, default: 1
      t.string :form_ids, array: true, default: []
      t.string :form_names, array: true, default: []
      t.string :form_routes, array: true, default: []
      t.string :mailchimp_ids, array: true, default: []
      t.integer :event_type
      t.timestamps 
    end
  end
end
