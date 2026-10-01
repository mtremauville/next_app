class CreateEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :entries do |t|
      t.string :title, null: false
      t.integer :status, null: false, default: 0
      t.integer :rating
      t.string :platform
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
