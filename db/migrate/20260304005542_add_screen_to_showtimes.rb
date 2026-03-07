class AddScreenToShowtimes < ActiveRecord::Migration[7.1]
  def change
    add_reference :showtimes, :screen, null: false, foreign_key: true
  end
end
