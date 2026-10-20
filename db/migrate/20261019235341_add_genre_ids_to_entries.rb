class AddGenreIdsToEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :entries, :genre_ids, :string
  end
end
