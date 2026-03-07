# Ensure movies show up in Movie.now_showing (release_date <= today)
# Non-destructive: does not delete any records.

Movie.find_each do |movie|
  next if movie.release_date.present? && movie.release_date <= Date.current
  movie.update!(release_date: Date.current - 7.days)
end

puts "✅ Marked movies as now showing: #{Movie.now_showing.count}"
