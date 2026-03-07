# BookMyTicket

Rails app for movie discovery and ticket booking with:
- Devise authentication
- seat selection + booking
- payment confirmation flow
- booking confirmation emails
- live movie sync for Indian now-playing titles

## Setup

```bash
bundle install
bin/rails db:create db:migrate
```

## Live Indian Movies (Posters + Trailers + Current Data)

Recommended stable source: `SerpAPI + OMDb` (cache-based, city-wise).

```bash
export LIVE_MOVIE_SOURCE=serpapi
export SERPAPI_KEY=your_serpapi_key
export OMDB_API_KEY=your_omdb_key
export SERPAPI_CITIES="mumbai,delhi,bengaluru,hyderabad,chennai,kolkata,pune,ahmedabad,kochi,jaipur"
export SERPAPI_CACHE_TTL_HOURS=6
export SERPAPI_REFRESH_COOLDOWN_MINUTES=30
bin/rails live_data:sync_movies
```

Cache files will be written per city in `tmp/serpapi_<city>.json`.
Page refreshes use cached data and avoid API hits until cache/cooldown expires.

Alternative source: BookMyShow scraping (`LIVE_MOVIE_SOURCE=bookmyshow`).
Because BookMyShow is Cloudflare-protected, use one of these modes:

1. Cookie mode (server-side fetch)
```bash
export LIVE_MOVIE_SOURCE=bookmyshow
export BMS_COOKIE='cf_clearance=...; other_cookie=...'
export OMDB_API_KEY=your_omdb_key
bin/rails live_data:sync_movies
```

2. Local HTML mode (recommended fallback)
- Open a BookMyShow city movie page in browser (for example `https://in.bookmyshow.com/explore/movies-mumbai`)
- Save page HTML as `tmp/bookmyshow_mumbai.html`
- Then run:

```bash
export LIVE_MOVIE_SOURCE=bookmyshow
export BMS_HTML_PATH=tmp/bookmyshow_mumbai.html
export OMDB_API_KEY=your_omdb_key
bin/rails live_data:sync_movies
```

Multi-city HTML import:
- Save one file per city, for example:
  - `tmp/bookmyshow_mumbai.html`
  - `tmp/bookmyshow_bangalore.html`
  - `tmp/bookmyshow_delhi.html`
- Then run:

```bash
export LIVE_MOVIE_SOURCE=bookmyshow
export BMS_HTML_GLOB='tmp/bookmyshow_*.html'
export OMDB_API_KEY=your_omdb_key
bin/rails live_data:sync_movies
```

Optional TMDB fallback:
```bash
export LIVE_MOVIE_SOURCE=tmdb
export TMDB_API_KEY=your_tmdb_key
bin/rails live_data:sync_movies
```

Offline India catalog (no API, no HTML paste):
```bash
export LIVE_MOVIE_SOURCE=offline_india
bin/rails live_data:sync_movies
```

Seed theaters/screens/showtimes:
```bash
bin/rails db:seed
```

## Confirmation Email (Real SMTP)

By default in development, emails open in Letter Opener.
To send real emails, set SMTP env vars:

```bash
export SMTP_ADDRESS=smtp.gmail.com
export SMTP_PORT=587
export SMTP_USERNAME=your_email@gmail.com
export SMTP_PASSWORD=your_app_password
export SMTP_DOMAIN=gmail.com
export SMTP_AUTHENTICATION=plain
export SMTP_ENABLE_STARTTLS_AUTO=true
export MAILER_FROM=your_email@gmail.com
export MAILER_HOST=localhost
export MAILER_PORT=3000
```

Then start the app:

```bash
bin/rails s
```

## Booking Flow

1. Sign in.
2. Pick movie -> city -> theater -> date -> showtime.
3. Select seats and click `Proceed to Payment`.
4. Click `Pay`.
5. Booking is confirmed and confirmation email is sent.
