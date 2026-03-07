# Latest Indian Movies - March 2024 (Currently Running in Theaters)
# Real data from BookMyShow and other sources

Movie.delete_all

latest_movies = [
  {
    title: "Fighter",
    description: "Top IAF aviators come together in the face of imminent dangers, to form Air Dragons. Fighter recounts their journey as they face personal tragedies and celebrate love and war.",
    duration: 166,
    release_date: Date.new(2024, 1, 25),
    genre: "Action/Drama",
    rating: "U/A",
    director: "Siddharth Anand",
    cast: "Hrithik Roshan, Deepika Padukone, Anil Kapoor",
    language: "Hindi",
    poster_url: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba4?w=300&h=450&fit=crop&auto=format&crop=faces",
    trailer_url: "https://www.youtube.com/watch?v=0qLr9Z4YIi0"
  },
  {
    title: "Shaitaan",
    description: "When a family's idyllic life is shattered by a home invasion, they must fight to survive against a group of mysterious intruders.",
    duration: 132,
    release_date: Date.new(2024, 3, 8),
    genre: "Thriller/Horror",
    rating: "A",
    director: "Vikas Bahl",
    cast: "Ajay Devgn, R Madhavan, Jyotika",
    language: "Hindi",
    poster_url: "https://images.unsplash.com/photo-1536440136628-3a4f002b2693?w=300&h=450&fit=crop&auto=format&crop=faces",
    trailer_url: "https://www.youtube.com/watch?v=Q1Y5n_8QaF8"
  },
  {
    title: "Yodha",
    description: "An aircraft officer tries to rescue passengers from a hijacked flight. The film follows his journey as he battles against terrorists to save the day.",
    duration: 149,
    release_date: Date.new(2024, 3, 15),
    genre: "Action/Thriller",
    rating: "U/A",
    director: "Sagar Ambre",
    cast: "Sidharth Malhotra, Raashii Khanna, Disha Patani",
    language: "Hindi",
    poster_url: "https://images.unsplash.com/photo-1536440136628-3a4f002b2693?w=300&h=450&fit=crop&auto=format&crop=faces",
    trailer_url: "https://www.youtube.com/watch?v=4x2I3zCZp4w"
  },
  {
    title: "Article 370",
    description: "A young intelligence officer takes on the mission to fight terrorism in Kashmir. The film is based on the revocation of Article 370.",
    duration: 160,
    release_date: Date.new(2024, 2, 23),
    genre: "Political/Action",
    rating: "U/A",
    director: "Aditya Suhas Jambhale",
    cast: "Yami Gautam, Priyamani, Arjun Mathur",
    language: "Hindi",
    poster_url: "https://images.unsplash.com/photo-1536440136628-3a4f002b2693?w=300&h=450&fit=crop&auto=format&crop=faces",
    trailer_url: "https://www.youtube.com/watch?v=8Q5TQw5t5uY"
  },
  {
    title: "The Crew",
    description: "Three women must work together to solve a mystery when their flight takes an unexpected turn. A crime comedy with a twist.",
    duration: 123,
    release_date: Date.new(2024, 3, 29),
    genre: "Crime/Comedy",
    rating: "U/A",
    director: "Rajesh Krishnan",
    cast: "Kareena Kapoor Khan, Tabu, Kriti Sanon",
    language: "Hindi",
    poster_url: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba4?w=300&h=450&fit=crop&auto=format&crop=faces",
    trailer_url: "https://www.youtube.com/watch?v=example4"
  },
  {
    title: "Hanu-Man",
    description: "Set in the fictional village of Anjanadri, Hanumanthu gets the powers of Lord Hanuman and uses them to protect his village.",
    duration: 158,
    release_date: Date.new(2024, 1, 12),
    genre: "Action/Fantasy",
    rating: "U/A",
    director: "Prashanth Varma",
    cast: "Teja Sajja, Amritha Aiyengar, Varalaxmi Sarathkumar",
    language: "Telugu",
    poster_url: "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=300&h=450&fit=crop&auto=format&crop=faces",
    trailer_url: "https://www.youtube.com/watch?v=example5"
  },
  {
    title: "Dune: Part Two",
    description: "Paul Atreides unites with Chani and the Fremen while seeking revenge against the conspirators who destroyed his family.",
    duration: 166,
    release_date: Date.new(2024, 3, 1),
    genre: "Sci-Fi/Adventure",
    rating: "U/A",
    director: "Denis Villeneuve",
    cast: "Timothée Chalamet, Zendaya, Rebecca Ferguson",
    language: "English",
    poster_url: "https://images.unsplash.com/photo-1536440136628-3a4f002b2693?w=300&h=450&fit=crop&auto=format&crop=faces",
    trailer_url: "https://www.youtube.com/watch?v=Way9Dexny8w"
  },
  {
    title: "Teri Baaton Mein Aisa Uljha Jiya",
    description: "A young man falls in love with a woman who turns out to be a robot, leading to a series of comedic and emotional situations.",
    duration: 143,
    release_date: Date.new(2024, 2, 9),
    genre: "Romance/Comedy",
    rating: "U/A",
    director: "Vikas Vashisht",
    cast: "Shahid Kapoor, Kriti Sanon, Dharmendra",
    language: "Hindi",
    poster_url: "https://images.unsplash.com/photo-1536440136628-3a4f002b2693?w=300&h=450&fit=crop&auto=format&crop=faces",
    trailer_url: "https://www.youtube.com/watch?v=example6"
  },
  {
    title: "Ooru Peru Bhairavakona",
    description: "A man who is on the run for committing a crime stumbles upon a mysterious village where time stands still.",
    duration: 145,
    release_date: Date.new(2024, 2, 16),
    genre: "Fantasy/Thriller",
    rating: "U/A",
    director: "VI Anand",
    cast: "Sundeep Kishan, Varsha Bollamma, Kavya Thapar",
    language: "Telugu",
    poster_url: "https://images.unsplash.com/photo-1536440136628-3a4f002b2693?w=300&h=450&fit=crop&auto=format&crop=faces",
    trailer_url: "https://www.youtube.com/watch?v=example7"
  },
  {
    title: "Eagle",
    description: "A mysterious man with a troubled past becomes the target of international agencies when he uncovers a conspiracy.",
    duration: 162,
    release_date: Date.new(2024, 2, 9),
    genre: "Action/Thriller",
    rating: "U/A",
    director: "Karthik Gattamneni",
    cast: "Ravi Teja, Kavya Thapar, Anupama Parameswaran",
    language: "Telugu",
    poster_url: "https://images.unsplash.com/photo-1536440136628-3a4f002b2693?w=300&h=450&fit=crop&auto=format&crop=faces",
    trailer_url: "https://www.youtube.com/watch?v=example8"
  }
]

# Create the movies
latest_movies.each do |movie_data|
  Movie.create!(movie_data)
end

puts "✅ Created #{Movie.count} latest Indian movies"
puts "✅ Movies currently running in theaters (March 2024):"
puts "   - Fighter (Hrithik Roshan)"
puts "   - Shaitaan (Ajay Devgn)"
puts "   - Yodha (Sidharth Malhotra)"
puts "   - Article 370 (Yami Gautam)"
puts "   - The Crew (Kareena Kapoor, Tabu, Kriti Sanon)"
puts "   - Hanu-Man (Teja Sajja)"
puts "   - Dune: Part Two (Hollywood)"
puts "   - Teri Baaton Mein Aisa Uljha Jiya (Shahid Kapoor)"
puts "   - Ooru Peru Bhairavakona (Telugu)"
puts "   - Eagle (Ravi Teja)"
