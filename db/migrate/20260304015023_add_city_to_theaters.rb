class AddCityToTheaters < ActiveRecord::Migration[7.1]
  def change
    add_column :theaters, :city, :string
  end
end
