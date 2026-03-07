# Update sample data for Indian cities and live movies
Showtime.delete_all
Screen.delete_all
Theater.delete_all
Movie.delete_all

# Currently running movies in India (March 2024)
movies = [
  {
    title: "Hanu-Man",
    description: "Set in the fictional village of Anjanadri, the film tells the story of Hanumanthu, a simple man with a heart of gold, who is worshipped and revered by the villagers.",
    duration: 159,
    release_date: Date.new(2024, 1, 12),
    genre: "Action/Adventure",
    rating: "U",
    director: "Prashanth Varma",
    cast: "Teja Sajja, Amritha Aiyengar, Varinder Singh Ghuman",
    language: "Telugu",
    poster_url: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba4?w=300&h=450&fit=crop",
    trailer_url: "https://www.youtube.com/watch?v=example1"
  },
  {
    title: "Dunki",
    description: "Four friends from a village in Punjab share a common dream: to go to England. Their only problem is that they don't have a visa or a ticket.",
    duration: 160,
    release_date: Date.new(2023, 12, 21),
    genre: "Comedy/Drama",
    rating: "U/A",
    director: "Rajkumar Hirani",
    cast: "Shah Rukh Khan, Taapsee Pannu, Boman Irani",
    language: "Hindi",
    poster_url: "https://images.unsplash.com/photo-1536440136628-3a4f002b2693?w=300&h=450&fit=crop",
    trailer_url: "https://www.youtube.com/watch?v=example2"
  },
  {
    title: "Salaar: Cease Fire",
    description: "A gang leader makes a promise to a dying friend by taking on other criminal gangs. The story is set in the city of Kolar Gold Fields.",
    duration: 175,
    release_date: Date.new(2023, 12, 22),
    genre: "Action/Crime",
    rating: "A",
    director: "Prashanth Neel",
    cast: "Prabhas, Prithviraj Sukumaran, Shruti Haasan",
    language: "Kannada",
    poster_url: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba4?w=300&h=450&fit=crop",
    trailer_url: "https://www.youtube.com/watch?v=example3"
  },
  {
    title: "Tiger 3",
    description: "Tiger and Zoya are back to save the country and their family. This time it's personal.",
    duration: 158,
    release_date: Date.new(2023, 11, 12),
    genre: "Action/Thriller",
    rating: "U/A",
    director: "Maneesh Sharma",
    cast: "Salman Khan, Katrina Kaif, Emraan Hashmi",
    language: "Hindi",
    poster_url: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba4?w=300&h=450&fit=crop",
    trailer_url: "https://www.youtube.com/watch?v=example4"
  },
  {
    title: "Jawan",
    description: "A man driven by a personal vendetta reforms criminals and corrects corruption in society with creative ideas.",
    duration: 169,
    release_date: Date.new(2023, 9, 7),
    genre: "Action/Drama",
    rating: "U/A",
    director: "Atlee",
    cast: "Shah Rukh Khan, Nayanthara, Vijay Sethupathi",
    language: "Hindi",
    poster_url: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba4?w=300&h=450&fit=crop",
    trailer_url: "https://www.youtube.com/watch?v=example5"
  },
  {
    title: "Gadar 2",
    description: "The story continues from where it left in Gadar: Ek Prem Katha. Tara Singh's life from 1985 to 2024 will be shown.",
    duration: 180,
    release_date: Date.new(2024, 2, 16),
    genre: "Action/Drama",
    rating: "U/A",
    director: "Anil Sharma",
    cast: "Sunny Deol, Utkarsh Sharma, Ameesha Patel",
    language: "Hindi",
    poster_url: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba4?w=300&h=450&fit=crop",
    trailer_url: "https://www.youtube.com/watch?v=example6"
  }
]

created_movies = Movie.create!(movies)

# Major Indian cities with theaters
theaters = [
  {
    name: "PVR Cinemas, Phoenix Marketcity",
    location: "Phoenix Marketcity, Whitefield, Bangalore, Karnataka 560066",
    city: "Bangalore"
  },
  {
    name: "INOX Movies, Nexus Shoppers Mall",
    location: "Nexus Shoppers Stop, Whitefield, Bangalore, Karnataka 560066",
    city: "Bangalore"
  },
  {
    name: "Cinepolis, Royal Meenakshi Mall",
    location: "Royal Meenakshi Mall, Brigade Road, Bangalore, Karnataka 560025",
    city: "Bangalore"
  },
  {
    name: "PVR Cinemas, Oberoi Mall",
    location: "Oberoi Mall, Goregaon, Mumbai, Maharashtra 400063",
    city: "Mumbai"
  },
  {
    name: "INOX Movies, Inorbit Mall",
    location: "Inorbit Mall, Malad, Mumbai, Maharashtra 400064",
    city: "Mumbai"
  },
  {
    name: "Cinepolis, Seawood Grand",
    location: "Seawood Grand, Seawoods, Navi Mumbai, Maharashtra 400706",
    city: "Mumbai"
  },
  {
    name: "PVR Cinemas, Express Avenue",
    location: "Express Avenue, Royapettah, Chennai, Tamil Nadu 600014",
    city: "Chennai"
  },
  {
    name: "INOX Movies, Phoenix Marketcity",
    location: "Phoenix Marketcity, Velachery, Chennai, Tamil Nadu 600042",
    city: "Chennai"
  },
  {
    name: "Sathyam Cinemas",
    location: "Rangarajapuram, Chennai, Tamil Nadu 600026",
    city: "Chennai"
  },
  {
    name: "PVR Cinemas, Select Citywalk",
    location: "Select Citywalk, Saket, New Delhi, Delhi 110017",
    city: "Delhi"
  },
  {
    name: "INOX Movies, Nehru Place",
    location: "Nehru Place, New Delhi, Delhi 110019",
    city: "Delhi"
  },
  {
    name: "Delite Cinemas",
    location: "Asaf Ali Road, Daryaganj, New Delhi, Delhi 110002",
    city: "Delhi"
  },
  {
    name: "PVR Cinemas, Forum Mall",
    location: "Forum Mall, Elgin, Kolkata, West Bengal 700071",
    city: "Kolkata"
  },
  {
    name: "INOX Movies, South City Mall",
    location: "South City Mall, Prince Anwar Shah Road, Kolkata, West Bengal 700045",
    city: "Kolkata"
  },
  {
    name: "89 Cinemas",
    location: "Elgin Road, Kolkata, West Bengal 700017",
    city: "Kolkata"
  }
]

created_theaters = Theater.create!(theaters)

# Create screens for each theater
screens = []
created_theaters.each do |theater|
  3.times do |i|
    screens << {
      name: "Screen #{i + 1}",
      capacity: 150,
      theater_id: theater.id
    }
  end
end

created_screens = Screen.create!(screens)

# Create showtimes for next 3 days (live booking)
showtimes = []
created_movies.each do |movie|
  created_screens.sample(4).each do |screen|
    # Showtimes for next 3 days
    3.times do |day_offset|
      showtime_date = Date.current + day_offset.days
      
      # Multiple showtimes per day
      ["09:00", "12:30", "16:00", "19:30", "22:45"].each do |time|
        start_time = Time.parse("#{showtime_date} #{time}")
        end_time = start_time + movie.duration.minutes
        
        showtimes << {
          movie_id: movie.id,
          theater_id: screen.theater_id,
          screen_id: screen.id,
          start_time: start_time,
          end_time: end_time,
          price: [120.00, 150.00, 180.00, 200.00].sample
        }
      end
    end
  end
end

Showtime.create!(showtimes)

puts "Created #{Movie.count} live Indian movies"
puts "Created #{Theater.count} theaters across major Indian cities"
puts "Created #{Screen.count} screens"
puts "Created #{Showtime.count} showtimes for next 3 days"
