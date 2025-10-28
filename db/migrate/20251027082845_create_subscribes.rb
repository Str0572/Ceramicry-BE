class CreateSubscribes < ActiveRecord::Migration[8.0]
  def change
    create_table :subscribes do |t|
      t.string :email

      t.timestamps
    end
  end
end
