# BookMyTicket – GitHub Copilot Instructions

## Project Overview
BookMyTicket is an Indian movie discovery and ticket booking web application built with **Ruby on Rails 7.1.6** and **Ruby 3.3.5**. Users can browse currently showing movies, select theaters by city, pick showtimes, choose seats, and complete payments via a Razorpay demo integration.

## Tech Stack
- **Language**: Ruby 3.3.5
- **Framework**: Rails 7.1.6
- **Database**: PostgreSQL
- **Frontend**: ERB templates, Hotwire (Turbo + Stimulus), Sprockets, import maps (no bundler/webpack)
- **Authentication**: Devise (email/password, bcrypt)
- **Payments**: Razorpay (demo flow)
- **Email**: ActionMailer + Letter Opener (development) + SMTP (production)
- **Testing**: Minitest + Capybara + Selenium WebDriver
- **Web Server**: Puma
- **Deployment**: Docker + AWS (ECS / EC2)

## Key Models
| Model | Description |
|-------|-------------|
| `User` | Devise-managed user with email/password; `has_many :bookings` |
| `Movie` | Title, description, duration, rating, genre, poster/trailer URLs, language; scopes: `now_showing`, `coming_soon` |
| `Theater` | Name, location, city; `has_many :screens` and `has_many :showtimes` |
| `Screen` | Name, capacity, `belongs_to :theater`; generates seat layouts (rows A–O, 10 cols) |
| `Showtime` | Links movie/theater/screen, tracks `booked_seats`, validates time/price |
| `Booking` | User + showtime + seats (JSON array) + `total_price` + `status` (pending/confirmed/cancelled/payment_failed) + Razorpay fields |

## Key Controllers
- `MoviesController` – index (filter by city/genre), show, live movie sync
- `BookingStepsController` – multi-step wizard: city → theater → date → time (state in session)
- `BookingsController` – new (seat selection), create, payment, payment_success, payment_failed, index
- `Admin::TheatersController` – CRUD for theaters, screens, and showtimes (admin namespace)
- `ApplicationController` – Devise layout, city session management (`session[:booking_city]`)

## Routing Conventions
- Root: `movies#index`
- Auth: `devise_for :users`
- Booking wizard: `GET /book/:movie_id` → `booking_steps#city|theater|date|time`
- Bookings nested under movies: `/movies/:movie_id/bookings`
- Admin namespace: `/admin/theaters` with nested screens and showtimes
- City selection: `POST /set_city`

## Services
| Service | Purpose |
|---------|---------|
| `LiveMovieSyncService` | TMDB API integration |
| `SerpapiSyncService` | SerpAPI + OMDb (city-wise, cache-based) |
| `BookMyShowSyncService` | BookMyShow HTML scraping |
| `OfflineIndiaSyncService` | Hardcoded fallback Indian movie catalog |
| `PaymentService` | Razorpay payment processing |

Switch between movie data sources using the `LIVE_MOVIE_SOURCE` environment variable.

## Environment Variables
Key env vars (see `.env` and `deployment-env-example.txt`):
- `DATABASE_URL` – PostgreSQL connection string
- `SERPAPI_KEY` – SerpAPI key for live movie data
- `TMDB_API_KEY` – TMDB API key
- `RAZORPAY_KEY_ID` / `RAZORPAY_KEY_SECRET` – payment gateway credentials
- `MAILER_FROM` – email sender address
- `SMTP_*` – SMTP server settings for production email
- `LIVE_MOVIE_SOURCE` – selects movie sync source (`serpapi`, `tmdb`, `bookmyshow`, `offline`)

## Development Setup
```bash
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server       # starts Puma on localhost:3000
```
Email previews available at `http://localhost:3000/letter_opener` in development.

## Testing
- **Framework**: Minitest (Rails default)
- **Run all tests**: `bin/rails test`
- **Run model tests**: `bin/rails test test/models`
- **Run controller tests**: `bin/rails test test/controllers`
- **Run system tests**: `bin/rails test:system`
- Fixtures live in `test/fixtures/`; all fixtures loaded by default
- Parallel test execution enabled (`parallelize(workers: :number_of_processors)`)

## Code Conventions
- Follow standard Rails MVC conventions (fat models, thin controllers)
- Use Devise helpers (`current_user`, `authenticate_user!`, `user_signed_in?`) for auth
- Store wizard/session state in `session[...]` (e.g., `session[:booking_city]`, `session[:theater_id]`)
- Use `before_action` for authorization and shared setup
- ERB templates; avoid inline JavaScript — use Stimulus controllers in `app/javascript/controllers/`
- Turbo Frames/Streams for partial page updates where applicable
- Background processing via ActiveJob (e.g., `MovieSyncJob`)
- Rake task for movie sync: `bin/rails live_data:sync_movies`

## Database
- Migrations in `db/migrate/`; current schema in `db/schema.rb`
- Seed data: `bin/rails db:seed`
- Notable columns: `bookings.seats` is a JSON array of seat identifiers

## Deployment
- Docker image built from `Dockerfile`
- AWS ECS: `ecs-task-definition.json`
- AWS EC2: `deploy-to-ec2.sh`, `deploy-ec2-fix.sh`
- Health check endpoint: `GET /up`

## Security Notes
- Sensitive parameters filtered from logs (`config/initializers/filter_parameter_logging.rb`)
- Content Security Policy configured (`config/initializers/content_security_policy.rb`)
- Razorpay signature verification on payment callbacks
- Never commit `.env`, `nirmir.pem`, or secrets to version control
