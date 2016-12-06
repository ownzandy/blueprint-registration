class AddEthnicityToPeople < ActiveRecord::Migration[5.0]
  def change
    add_column :people, :ethnicity, :string
  end
end
