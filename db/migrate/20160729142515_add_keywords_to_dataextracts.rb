class AddKeywordsToDataextracts < ActiveRecord::Migration
  def change
  	  add_column :dataextracts, :conceptkeywords, :text
  	  add_column :dataextracts, :entitykeywords, :text
  end
end