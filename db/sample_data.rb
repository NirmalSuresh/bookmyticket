# Sample data seeding
Movie.delete_all
Theater.delete_all
Screen.delete_all
Showtime.delete_all

# Create sample movies
movies = [
  {
    title: "Dune: Part Two",
    description: "Paul Atreides unites with Chani and the Fremen while seeking revenge against the conspirators who destroyed his family. Facing a choice between the love of his life and the fate of the universe, he endeavors to prevent a terrible future.",
    duration: 166,
    release_date: Date.new(2024, 3, 1),
    genre: "Sci-Fi",
    rating: "PG-13",
    director: "Denis Villeneuve",
    cast: "Timothée Chalamet, Zendaya, Rebecca Ferguson",
    language: "English",
    poster_url: "https://via.placeholder.com/300x450/4a5568/ffffff?text=Dune+Part+Two",
    trailer_url: "https://www.youtube.com/watch?v=Way9Dexny3w"
  },
  {
    title: "Oppenheimer",
    description: "The story of American scientist J. Robert Oppenheimer and his role in the development of the atomic bomb during World War II.",
    duration: 180,
    release_date: Date.new(2023, 7, 21),
    genre: "Biography",
    rating: "R",
    director: "Christopher Nolan",
    cast: "Cillian Murphy, Emily Blunt, Matt Damon",
    language: "English",
    poster_url: "https://via.placeholder.com/300x450/4a5568/ffffff?text=Oppenheimer",
    trailer_url: "https://www.youtube.com/watch?v=uYPbbksJxIg"
  },
  {
    title: "Barbie",
    description: "Barbie and Ken are having the time of their lives in the colorful and seemingly perfect world of Barbie Land. However, when they get a chance to go to the real world, they soon discover the joys and perils of living among humans.",
    duration: 114,
    release_date: Date.new(2023, 7, 21),
    genre: "Comedy",
    rating: "PG-13",
    director: "Greta Gerwig",
    cast: "Margot Robbie, Ryan Gosling, Issa Rae",
    language: "English",
    poster_url: "https://via.placeholder.com/300x450/ff6b6b/ffffff?text=Barbie",
    trailer_url: "https://www.youtube.com/watch?v=pBk4NYhWNMM"
  },
  {
    title: "The Batman",
    description: "When the Riddler, a sadistic serial killer, begins murdering key political figures in Gotham, Batman is forced to investigate the city's hidden corruption and question his family's involvement.",
    duration: 176,
    release_date: Date.new(2022, 3, 4),
    genre: "Action",
    rating: "PG-13",
    director: "Matt Reeves",
    cast: "Robert Pattinson, Zoë Kravitz, Jeffrey Wright",
    language: "English",
    poster_url: "https://via.placeholder.com/300x450/2d3748/ffffff?text=The+Batman",
    trailer_url: "https://www.youtube.com/watch?v=mqqft2x_Aa4"
  }
]

created_movies = Movie.create!(movies)

# Create sample theaters
theaters = [
  {
    name: "AMC Times Square",
    location: "234 W 42nd St, New York, NY 10036"
  },
  {
    name: "Regal Union Square",
    location: "850 Broadway, New York, NY 10003"
  },
  {
    name: "Cinema Village",
    location: "22 E 12th St, New York, NY 10003"
  }
]

created_theaters = Theater.create!(theaters)

# Create screens for each theater
screens = []
created_theaters.each do |theater|
  3.times do |i|
    screens << {
      name: "Screen #{i + 1}",
      capacity: 120,
      theater_id: theater.id
    }
  end
end

created_screens = Screen.create!(screens)

# Create sample showtimes
showtimes = []
created_movies.each do |movie|
  created_screens.sample(2).each do |screen|
    # Create showtimes for the next 7 days
    7.times do |day_offset|
      showtime_date = Date.current + day_offset.days
      
      # Multiple showtimes per day
      ["13:00", "16:30", "19:30", "22:00"].each do |time|
        start_time = Time.parse("#{showtime_date} #{time}")
        end_time = start_time + movie.duration.minutes
        
        showtimes << {
          movie_id: movie.id,
          theater_id: screen.theater_id,
          screen_id: screen.id,
          start_time: start_time,
          end_time: end_time,
          price: [12.99, 14.99, 16.99].sample
        }
      end
    end
  end
end

Showtime.create!(showtimes)

puts "Created #{Movie.count} movies"
puts "Created #{Theater.count} theaters"
puts "Created #{Screen.count} screens"
puts "Created #{Showtime.count} showtimes"
