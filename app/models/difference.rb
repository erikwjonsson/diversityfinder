class Difference < ActiveRecord::Base
  require 'difference_calculator'


  def self.comparison_calculation
    dataextracts = Dataextract.all

    @array_of_differences_of_one_article_compared_to_all_articles = DifferenceCalculator.new.comparison(Dataextract.all)

    @array_of_differences_of_one_article_compared_to_all_articles.each_slice(4) do |base_article_url, comparator_article_url, total_weight_entities, total_weight_concepts|
      base_article_id = Dataextract.find_by(url: base_article_url).id
      comparator_article_id = Dataextract.find_by(:url => comparator_article_url).id

      if Difference.exists?(dataextraction1: base_article_id, dataextraction2: comparator_article_id) || base_article_id == comparator_article_id
        difference_record = Difference.find_by(dataextraction1: base_article_id, dataextraction2: comparator_article_id)
        unless difference_record.nil? # SHUOLD NOT BE NECESSARY, BUT IS
          difference_record.update_attributes(entities_diff: total_weight_entities, concepts_diff: total_weight_concepts)
        end
      else
        Difference.create(dataextraction1: base_article_id, dataextraction2: comparator_article_id, entities_diff: total_weight_entities, concepts_diff: total_weight_concepts)
      end
    end
  end

end
