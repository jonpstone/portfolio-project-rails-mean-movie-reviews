class AddBannerToReviews < ActiveRecord::Migration[5.0]
  def change
    add_column :reviews, :banner, :string
  end
end
