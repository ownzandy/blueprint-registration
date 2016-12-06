class AddEmergencyContactsToPeople < ActiveRecord::Migration[5.0]
  def change
    add_column :people, :emergency_contacts, :string
  end
end
