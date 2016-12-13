class AddCustomToSpeakers < ActiveRecord::Migration[5.0]
  def change
    add_column :speakers, :custom, :string, array: true, default: []
  end
end
