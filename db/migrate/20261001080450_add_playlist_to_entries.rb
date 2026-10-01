class AddPlaylistToEntries < ActiveRecord::Migration[8.1]
  def change
    add_reference :entries, :playlist, null: true, foreign_key: true
  end
end
