class CreateWords < ActiveRecord::Migration
  def change
    create_table :words do |t|
      t.string :url
      t.string :concepts_list
      t.string :entities_list
      
      t.timestamps null: false
    end
  end
end
