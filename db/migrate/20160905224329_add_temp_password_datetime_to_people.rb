class AddTempPasswordDatetimeToPeople < ActiveRecord::Migration[5.0]
  def change
    add_column :people, :temp_password_datetime, :datetime
  end
end
