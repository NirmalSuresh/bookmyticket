class AddFieldsToMovies < ActiveRecord::Migration[7.1]
  def change
    add_column :movies, :genre, :string
    add_column :movies, :rating, :string
    add_column :movies, :poster_url, :string
    add_column :movies, :trailer_url, :string
    add_column :movies, :cast, :text
    add_column :movies, :director, :string
    add_column :movies, :language, :string
  end
end
