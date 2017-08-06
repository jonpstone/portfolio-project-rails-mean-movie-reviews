class CreateWriters < ActiveRecord::Migration[5.0]
  def change
    create_table :writers do |t|
      t.string :name
      t.publication :string
      t.bio :text

      t.timestamps
    end
  end
end
