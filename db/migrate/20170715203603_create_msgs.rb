class CreateMsgs < ActiveRecord::Migration[5.1]
  def change
    create_table :msgs do |t|
      t.integer :user_id
      t.string :text
      t.string :channel
      t.string :ip
      t.string :category
      t.string :username

      t.timestamps
    end
  end
end
