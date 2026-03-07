require 'net/http'
require 'json'

api_key = ENV['OMDB_API_KEY']
if api_key.nil? || api_key.strip.empty?
  raise "OMDB_API_KEY is missing. Set it and re-run. Example: OMDB_API_KEY=xxxx bin/rails runner db/omdb_backfill_posters.rb"
end

def omdb_fetch_by_title(title, api_key)
  uri = URI('http://www.omdbapi.com/')
  uri.query = URI.encode_www_form({ t: title, apikey: api_key })
  res = Net::HTTP.get_response(uri)
  return nil unless res.is_a?(Net::HTTPSuccess)

  json = JSON.parse(res.body)
  return nil if json['Response'] != 'True'

  json
rescue JSON::ParserError
  nil
end

def omdb_search(title, api_key)
  uri = URI('http://www.omdbapi.com/')
  uri.query = URI.encode_www_form({ s: title, apikey: api_key })
  res = Net::HTTP.get_response(uri)
  return nil unless res.is_a?(Net::HTTPSuccess)

  json = JSON.parse(res.body)
  return nil if json['Response'] != 'True'
  json
rescue JSON::ParserError
  nil
end

def omdb_fetch_by_imdb_id(imdb_id, api_key)
  uri = URI('http://www.omdbapi.com/')
  uri.query = URI.encode_www_form({ i: imdb_id, apikey: api_key })
  res = Net::HTTP.get_response(uri)
  return nil unless res.is_a?(Net::HTTPSuccess)

  json = JSON.parse(res.body)
  return nil if json['Response'] != 'True'
  json
rescue JSON::ParserError
  nil
end

updated = 0
skipped = 0
failed = 0

Movie.find_each do |movie|
  data = omdb_fetch_by_title(movie.title, api_key)
  if data.nil?
    search = omdb_search(movie.title, api_key)
    imdb_id = search&.dig('Search')&.first&.fetch('imdbID', nil)
    data = omdb_fetch_by_imdb_id(imdb_id, api_key) if imdb_id
  end
  if data.nil?
    failed += 1
    next
  end

  attrs = {}

  poster = data['Poster']
  attrs[:poster_url] = poster if poster && poster != 'N/A'

  runtime = data['Runtime']
  if runtime && runtime != 'N/A'
    minutes = runtime.to_s[/\d+/]&.to_i
    attrs[:duration] = minutes if minutes && minutes > 0
  end

  genre = data['Genre']
  attrs[:genre] = genre if genre && genre != 'N/A'

  director = data['Director']
  attrs[:director] = director if director && director != 'N/A'

  actors = data['Actors']
  attrs[:cast] = actors if actors && actors != 'N/A'

  language = data['Language']
  # Your app expects a single language; take the first if multiple
  if language && language != 'N/A'
    attrs[:language] = language.split(',').first.strip
  end

  rated = data['Rated']
  # Only map if it matches our validation list
  if rated && %w[U U/A PG PG-13 A R].include?(rated)
    attrs[:rating] = rated
  end

  if attrs.empty?
    skipped += 1
    next
  end

  movie.update!(attrs)
  updated += 1
end

puts "✅ OMDb backfill complete"
puts "   Updated: #{updated}"
puts "   Skipped: #{skipped}"
puts "   Failed:  #{failed}"
