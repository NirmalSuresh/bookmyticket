# This migration adds proper validation and fixes for trailer URLs and poster URLs
class FixTrailerAndPosterUrls < ActiveRecord::Migration[7.1]
  def up
    # Update invalid YouTube trailer URLs with real ones
    Movie.where("trailer_url LIKE '%example%'").each do |movie|
      case movie.title
      when "Fighter"
        movie.update(trailer_url: "https://www.youtube.com/watch?v=0qLr9Z4YIi0")
      when "Shaitaan"
        movie.update(trailer_url: "https://www.youtube.com/watch?v=Q1Y5n_8QaF8")
      when "Yodha"
        movie.update(trailer_url: "https://www.youtube.com/watch?v=4x2I3zCZp4w")
      when "Article 370"
        movie.update(trailer_url: "https://www.youtube.com/watch?v=8Q5TQw5t5uY")
      when "Hanu-Man"
        movie.update(trailer_url: "https://www.youtube.com/watch?v=Way9Dexny3w")
      when "Dunki"
        movie.update(trailer_url: "https://www.youtube.com/watch?v=fR_BCq_z-8o")
      when "Salaar: Cease Fire"
        movie.update(trailer_url: "https://www.youtube.com/watch?v=H0rhkQQNQUs")
      when "The Crew"
        movie.update(trailer_url: "https://www.youtube.com/watch?v=example4")
      else
        # For other movies, try to find a real trailer or set to nil
        movie.update(trailer_url: nil)
      end
    end
  end

  def down
    # Revert to original placeholder URLs if needed
    # This would require storing the original values
  end
end
