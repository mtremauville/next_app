class AddTmdbFieldsToEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :entries, :tmdb_id, :integer
    add_column :entries, :media_type, :string
    add_column :entries, :poster_path, :string
    add_column :entries, :year, :string
    add_column :entries, :overview, :text
  end
end
