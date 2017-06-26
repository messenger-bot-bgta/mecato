class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string :messenger_id
      t.references :shop
      t.string :step

      t.timestamps
    end
  end
end
