namespace :showtimes do
  desc "Refresh showtimes: roll expired ones forward and fill next 14 days for all theaters & movies"
  task refresh: :environment do
    show_slots = ['10:00', '13:00', '16:00', '19:00', '22:00']
    prices     = [220, 250, 280, 300]

    movies  = Movie.all.to_a
    screens = Screen.includes(:theater).all.to_a

    if movies.empty? || screens.empty?
      puts "No movies or screens found. Run db:seed first."
      next
    end

    created = 0
    (0..14).each do |day_offset|
      date = Date.current + day_offset.days
      movies.each do |movie|
        screens.sample([screens.count / 2, 4].max).each_with_index do |screen, idx|
          slot       = show_slots[idx % show_slots.size]
          start_time = Time.zone.parse("#{date} #{slot}")
          duration   = (movie.duration.presence || 150).to_i
          end_time   = start_time + duration.minutes
          price      = prices.sample

          next if Showtime.exists?(movie: movie, screen: screen, start_time: start_time)
          Showtime.create!(
            movie:      movie,
            screen:     screen,
            theater:    screen.theater,
            start_time: start_time,
            end_time:   end_time,
            price:      price
          )
          created += 1
        end
      end
    end

    puts "Created #{created} new showtimes. Total future: #{Showtime.where('start_time > ?', Time.current).count}"
  end
end
