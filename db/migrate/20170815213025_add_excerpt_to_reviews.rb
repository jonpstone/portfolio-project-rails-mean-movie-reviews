class AddExcerptToReviews < ActiveRecord::Migration[5.0]
  def change
    add_column :reviews, :excerpt, :text
  end
end
