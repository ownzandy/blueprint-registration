class AddDietaryRestrictionsToPeople < ActiveRecord::Migration[5.0]
  def change
    add_column :people, :dietary_restrictions, :string, array: true, default: []
  end
end
