# Fix showtimes - Ensure every movie has showtimes at every theater
Showtime.delete_all

screens = Screen.all
movies = Movie.all
theaters = Theater.all

puts "Creating showtimes for #{movies.count} movies at #{theaters.count} theaters..."

# Create realistic showtimes for next 7 days - EVERY movie at EVERY theater
showtimes = []
movies.each do |movie|
  theaters.each do |theater|
    # Get screens for this theater
    theater_screens = screens.where(theater_id: theater.id)
    
    theater_screens.each do |screen|
      # Showtimes for next 7 days
      7.times do |day_offset|
        showtime_date = Date.current + day_offset.days
        
        # Multiple showtimes per day (realistic schedule)
        showtime_schedule = case movie.title
                         when "Fighter", "Shaitaan", "Yodha", "Article 370"
                           ["09:00", "12:30", "15:45", "19:00", "22:30"] # More shows for popular movies
                         when "Hanu-Man", "The Crew"
                           ["10:00", "13:30", "16:45", "20:00"] # Regular shows
                         else
                           ["11:00", "14:30", "18:00", "21:30"] # Fewer shows for newer releases
                         end
        
        showtime_schedule.each do |time|
          begin
            start_time = Time.parse("#{showtime_date} #{time}")
            end_time = start_time + movie.duration.minutes
            
            # Skip past showtimes
            next if start_time <= Time.current
            
            # Realistic pricing based on movie popularity and time
            base_price = case movie.title
                       when "Fighter", "Shaitaan", "Yodha", "Article 370"
                         [180.00, 200.00, 220.00, 250.00].sample # Higher prices for popular movies
                       when "Hanu-Man", "The Crew"
                         [150.00, 180.00, 200.00].sample # Medium prices
                       else
                         [120.00, 150.00, 180.00].sample # Lower prices for newer releases
                       end
            
            showtimes << {
              movie_id: movie.id,
              theater_id: theater.id,
              screen_id: screen.id,
              start_time: start_time,
              end_time: end_time,
              price: base_price
            }
          rescue => e
            puts "Error creating showtime: #{e.message}"
          end
        end
      end
    end
  end
end

Showtime.create!(showtimes)

puts "✅ Created #{Showtime.count} showtimes"
puts "✅ Each movie now has showtimes at every theater"
puts "✅ Total combinations: #{movies.count} movies × #{theaters.count} theaters × #{screens.count/theaters.count} screens × 7 days"
