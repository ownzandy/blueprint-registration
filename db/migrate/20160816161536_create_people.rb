class CreatePeople < ActiveRecord::Migration[5.0]
  def change
    create_table :people do |t|
   	  t.string :first_name
      t.string :last_name
      t.string :gender
      t.string :email
      t.string :phone
      t.string :form_id, array: true, default: []
      t.string :submit_date, array: true, default: []
      t.timestamps
    end
  end
end
