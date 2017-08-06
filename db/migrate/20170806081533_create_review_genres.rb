class CreateReviewGenres < ActiveRecord::Migration[5.0]
  def change
    create_table :review_genres do |t|
      t.integer :genre_id
      t.integer :review_id

      t.timestamps
    end
  end
end
