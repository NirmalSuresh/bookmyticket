# Create theaters and showtimes for the REAL current movies

# Delete in correct order to avoid foreign key constraints
Showtime.delete_all
Screen.delete_all
Theater.delete_all

# Create theaters in major cities
theaters_data = [
  { name: "PVR Phoenix Marketcity", location: "Bangalore - Phoenix Marketcity, Whitefield" },
  { name: "INOX Nexus Mall", location: "Bangalore - Nexus Mall, Koramangala" },
  { name: "Cinepolis Royal Meenakshi Mall", location: "Bangalore - Royal Meenakshi Mall, Bannerghatta Road" },
  
  { name: "PVR Jio World Drive", location: "Mumbai - Jio World Drive, Bandra Kurla Complex" },
  { name: "INOX Inorbit Mall", location: "Mumbai - Inorbit Mall, Malad" },
  { name: "Cinepolis Oberoi Mall", location: "Mumbai - Oberoi Mall, Goregaon" },
  
  { name: "PVR Ampa Skywalk", location: "Chennai - Ampa Skywalk Mall, Aminjikarai" },
  { name: "INOX Chennai Citi Centre", location: "Chennai - Chennai Citi Centre, Radhakrishnan Salai" },
  { name: "SPI Palazzo", location: "Chennai - Phoenix Palazzo, Velachery" },
  
  { name: "PVR Select City Walk", location: "Delhi - Select City Walk, Saket" },
  { name: "INOX DLF Place", location: "Delhi - DLF Place, Saket" },
  { name: "Cinepolis DLF Mall of India", location: "Delhi - DLF Mall of India, Noida" },
  
  { name: "PVR South City Mall", location: "Kolkata - South City Mall, Prince Anwar Shah Road" },
  { name: "INOX Quest Mall", location: "Kolkata - Quest Mall, Syed Amir Ali Avenue" },
  { name: "Cinepolis Acropolis Mall", location: "Kolkata - Acropolis Mall, Rajarhat" }
]

theaters_data.each do |theater_data|
  Theater.create!(theater_data)
end

puts "✅ Created #{Theater.count} theaters"

# Create screens for each theater
Screen.delete_all
Theater.all.each do |theater|
  3.times do |i|
    Screen.create!(
      name: "Screen #{i + 1}",
      theater: theater,
      capacity: 120 + (i * 30) # Varying capacities: 120, 150, 180
    )
  end
end

puts "✅ Created #{Screen.count} screens"

# Create showtimes for all movies at all theaters for the next 7 days
Showtime.delete_all
movies = Movie.all
theaters = Theater.all

movies.each do |movie|
  theaters.each do |theater|
    theater.screens.each do |screen|
      # Create showtimes for the next 7 days
      (0..6).each do |day_offset|
        date = Date.today + day_offset
        
        # Multiple showtimes per day
        daily_times = ["10:30", "13:45", "16:30", "19:15", "22:00"]
        
        daily_times.each do |time_str|
          start_time = Time.parse("#{date} #{time_str}")
          end_time = start_time + movie.duration.minutes
          
          # Dynamic pricing based on movie popularity and time
          base_price = case movie.title
                      when "Dhurandhar: The Revenge", "Toxic: A Fairy Tale for Grown-Ups"
                        250
                      when "Aadu 3", "Ustaad Bhagat Singh"
                        200
                      else
                        180
                      end
          
          # Weekend and evening pricing
          if date.saturday? || date.sunday?
            base_price += 50
          elsif start_time.hour >= 18
            base_price += 30
          end
          
          Showtime.create!(
            movie: movie,
            theater: theater,
            screen: screen,
            start_time: start_time,
            end_time: end_time,
            price: base_price
          )
        end
      end
    end
  end
end

puts "✅ Created #{Showtime.count} showtimes"
puts "✅ Showtimes created for:"
puts "   - #{Movie.count} movies"
puts "   - #{Theater.count} theaters" 
puts "   - #{Screen.count} screens"
puts "   - Next 7 days with multiple showtimes daily"
puts ""
puts "🎬 Your BookMyTicket is now ready with REAL current movies!"
puts "📅 Visit http://localhost:3000 to book tickets for current releases!"
