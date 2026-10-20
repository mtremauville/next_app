namespace :entries do
  desc "Fill genre_ids for entries added before they were stored"
  task backfill_genre_ids: :environment do
    scope = Entry.where.not(tmdb_id: nil).where(genre_ids: [ nil, "" ])
    total = scope.count
    done = 0

    scope.find_each do |entry|
      details = Tmdb::Details.new.call(entry.tmdb_id, entry.media_type)
      next unless details

      entry.update_columns(genre_ids: details.genre_ids.join(","))
      done += 1
    end

    puts "#{done}/#{total} titres mis à jour."
  end
end
