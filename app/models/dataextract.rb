class Dataextract < ActiveRecord::Base
  # probably shoudl turn this into a module.
  # http://stackoverflow.com/questions/151505/difference-between-a-class-and-a-module
  require 'alchemy_caller'
  #require File.join(Rails.root, "lib/alchemy_caller.rb")

  def self.create_alchemy_extract(url)

    @url = url
    unless self.exists?(url: @url)
      u = AlchemyCaller.new
      
      @concepts_list, @entities_list, @keyword_concept_check, @keyword_entity_check = u.send_query_to_alchemy(@url)

      if @keyword_entity_check.length != 0 && @keyword_concept_check.length != 0
        Dataextract.create(url: url, concepts_list: @concepts_list, entities_list: @entities_list)
      elsif @keyword_entity_check.length == 0
        flash[:notice] = "Alchemy could not identify any ENTITY keywords. URL was not added to database!"
      elsif @keyword_concept_check.length == 0
        flash[:notice] = "Alchemy could not identify any CONCEPT keywords. URL was not added to database!"
      end

    end
  end

  #DifferenceCalculator.new.comparison


end