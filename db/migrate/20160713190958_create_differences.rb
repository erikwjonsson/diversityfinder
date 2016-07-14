class CreateDifferences < ActiveRecord::Migration
  def change
    create_table :differences do |t|
      t.integer :dataextraction1
      t.integer :dataextraction2
      t.decimal :entities_diff
      t.decimal :concepts_diff

      t.timestamps null: false
    end
  end
end
