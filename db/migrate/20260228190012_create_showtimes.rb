class CreateShowtimes < ActiveRecord::Migration[7.1]
  def change
    create_table :showtimes do |t|
      t.references :movie, null: false, foreign_key: true
      t.references :theater, null: false, foreign_key: true
      t.datetime :start_time
      t.datetime :end_time
      t.decimal :price

      t.timestamps
    end
  end
end
