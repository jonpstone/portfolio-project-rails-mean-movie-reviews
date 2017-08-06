class CreateReviews < ActiveRecord::Migration[5.0]
  def change
    create_table :reviews do |t|
      t.string :title
      t.text :content
      t.string :date_published
      t.integer :year
      t.integer :writer_id

      t.timestamps
    end
  end
end
