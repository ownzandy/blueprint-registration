class AddTempPasswordToPeople < ActiveRecord::Migration[5.0]
  def change
    add_column :people, :temp_password, :string
  end
end
