class CreateDataextracts < ActiveRecord::Migration
  def change
    create_table :dataextracts do |t|
      t.string :url
      t.string :concepts_list
      t.string :entities_list
      t.text :conceptkeywords
      t.text :entitykeywords
      
      t.timestamps null: false
    end
  end
end


