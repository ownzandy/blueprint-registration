class AddSessionTokenToPeople < ActiveRecord::Migration[5.0]
  def change
    add_column :people, :session_token, :string
  end
end
