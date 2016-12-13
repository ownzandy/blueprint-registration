class AddSizeToPeople < ActiveRecord::Migration[5.0]
  def change
    add_column :people, :size, :string
  end
end
