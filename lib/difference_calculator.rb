class DifferenceCalculator

  def comparison(alchemy_json) # Calculates the differences in matching entity and concept keywords between every article (base article) against all other articles (comparator articles).

    calculation_output = []
    
    keywords_and_urls_of_all_articles = extract_keywords_and_urls_from_alchemy_JSON(alchemy_json)
    # Produces this: {:url=>"https://www.theguardian.com/news/2016/apr/03/the-panama-papers-how-the-worlds-rich-and-famous-hide-their-money-offshore", :entities=>["prime minister", "Mossack Fonseca", "Panama Papers"], :concepts=>["Tax haven", "British Virgin Islands", "Offshore company"]}

    keywords_and_urls_of_all_articles.each do |base_article| # Declares the base article every loop. Base article does not refer to an actual article. It refers to the url, entity keywords and concept keywords of an online article.
      
      # THIS ONLY SEEMS TO REMOVE THE URL??
      base_article_keywords_hash = {entities: base_article[:entities], :concepts => base_article[:concepts]} # {:entities=>["prime minister", "Mossack Fonseca", "Panama Papers"], :concepts=>["Tax haven", "British Virgin Islands", "Offshore company"]}

      @array_of_differences_of_one_article_compared_to_all_articles = calculation(base_article_keywords_hash, base_article[:url], keywords_and_urls_of_all_articles)

    end

    return @array_of_differences_of_one_article_compared_to_all_articles

  end

  def calculation(base_article_keywords_hash, base_article_url, keywords_and_urls_of_all_articles) # THIS IS FOR ONE SINGLE ARTICLE VERSUS ALL OTHERS
 
    @array_of_differences_of_one_article_compared_to_all_articles = []

    keywords_and_urls_of_all_articles.each do |comparator_article| # Loops through each article data set to declare as comparator.
      
      base_article_keywords_hash.each do |keyword_category, base_article_keywords| # Alternates between choosing 
        comparator_keywords = comparator_article[:"#{keyword_category}"]

        @total_weight = calculate_similarity(base_article_keywords, comparator_keywords)

        #print_output_start("#{keyword_category}", base_article_url, base_article_keywords, comparator_article[:url], comparator_keywords, total_weight, weight_per_keyword)
        #(print_output_zero(total_weight) && total_weight = 0) if total_weight < 0 # If total weight below zero, set to zero.
        #@total_weight = total_weight
        #@total_weight_concepts = total_weight if keyword_category == 'concepts'
        #print_output_ending(total_weight)

        @array_of_differences_of_one_article_compared_to_all_articles = load_values(base_article_url, comparator_article[:url], keyword_category, @total_weight, @array_of_differences_of_one_article_compared_to_all_articles)

      end

    end
    return @array_of_differences_of_one_article_compared_to_all_articles
  end


  private

  def extract_keywords_and_urls_from_alchemy_JSON(alchemy_json) # Parses the JSON strings from Alchemy stored in the database.
    keywords_and_urls_of_all_articles = []
    alchemy_json.each do |p|
      if check_if_empty?(p) == true
        entity_keywords = parse_json_for_keywords('entities', p)
        concept_keywords = parse_json_for_keywords('concepts', p)
        article_data = {:url => p.url, :entities => entity_keywords, :concepts => concept_keywords}
        keywords_and_urls_of_all_articles.push(article_data) # pushes hash to master hash
      end
    end
    return keywords_and_urls_of_all_articles
  end

  def parse_json_for_keywords(keyword_keyword_category, dataextract) # Valid keywordkeyword_categorys: 'concepts' and 'entities'
    keywords = []
    JSON.parse(dataextract.send("#{keyword_keyword_category}_list"))["#{keyword_keyword_category}"].each {|e| keywords.push(e['text'])}
    keywords.uniq # Read more below #1
  end

  def check_if_empty?(p)
  (p.entities_list.present? && p.concepts_list.present? && p.url.present?) ? true : false
  end

  def set_weights(keywords)
    total_weight = 30.0

    if keywords.count == 0
      no_keywords = true
    else
      weight_per_keyword = total_weight / keywords.count
      no_keywords = false
    end
    return total_weight, weight_per_keyword, no_keywords
  end

  def calculate_similarity(base_article_keywords, comparator_keywords)
    total_weight, weight_per_keyword, no_keywords = set_weights(comparator_keywords)

    unless no_keywords == true
      base_article_keywords.each do |base_article_keyword| # check how many times concept keyword exists and subtract weight if found.
        (comparator_keywords.include? base_article_keyword) ? (total_weight = total_weight - weight_per_keyword) : total_weight
  #      (comparator_keywords.include? base_article_keyword) ? (total_weight = total_weight - weight_per_keyword ; puts base_article_keyword + "   #{total_weight}") : total_weight
      end
    else
      total_weight = 0.0
    end
    return total_weight
  end

  def load_values(base_article_url, comparator_article, keyword_category, total_weight, calculation_output)
    if keyword_category == :entities
      calculation_output << base_article_url
      calculation_output << comparator_article
      calculation_output << total_weight
    else
      calculation_output << total_weight
    end
    return calculation_output
  end

  def save_differences_after_calculation
    Difference.create(dataextraction1: base_article_id, dataextraction2: comparator_article_id, entities_diff: @total_weight_entities, concepts_diff: @total_weight_concepts)
  end

end






























# DataExtract



  def print_output_start(keyword_category, base_article_url, base_article_keywords_hash, comparator_article_url, comparator_keywords, total_weight, weight_per_keyword)
    puts "=================== # CALCULATOR #{keyword_category} # ==================="
    puts ""
    puts "FIRST URL"
    puts base_article_url
    puts ""
    print base_article_keywords_hash
    puts ""
    puts "Number of entitiy keywords in base:"
    puts base_article_keywords_hash.count
    puts ""
    puts ""
    puts "SECOND URL"
    puts comparator_article_url
    puts ""
    print comparator_keywords
    puts ""
    puts "Number of concept keywords in comparator:"
    puts comparator_keywords.count
    puts ""
    puts ""
    puts "Total weight:"
    puts total_weight
    puts ""
    puts "Weight per entity:"
    puts weight_per_keyword
    puts ""
    puts "---------- KEYWORDS MATCHES ----------"
  end

  def print_output_zero(total_weight)
    puts "====== !!!!!! SUB-ZERO !!!!!! ======"
    puts ""
    puts total_weight
    puts ""
    puts "ROUNDED UP TO ZERO ===> 0"
    puts ""
  end

  def print_output_ending(total_weight)
    puts "--------------------------------------"
    puts ""
    puts "TOTAL WEIGHT TO INSERT: "
    puts total_weight
    puts ""
    puts ""
    puts "=================== # END # ==================="
    puts ""
    puts ""
    puts ""
    puts ""
    puts ""
    puts ""
    puts ""
  end




=begin

========================ISSUES=======================

a.  For some reason when comparing the same article againt itself it flips out in the last part of the loop.
    It removes to much weight so it becomes below zero.
    SUGGESTED SOLUTION: Not calculating the difference between itself is not needed. Ask it to skip.


#1 Removes dublicate keywords which Alchemy might output

Alchemy seems to have issues with some URLs. 
It outputs the exact same keyword several times, but seems to think the keyword is different concepts or entities.
Example URL - https://en.wikipedia.org/wiki/Panama_Papers
With the example URL Alchemy outputs that "Mossack Fonseca" is a Person, City, Company and GeographicFeature.
So the keyword "Mossack Fonseca" appears four times.'

SUGGESTED SOLUTION: 
Remove duplicates when parsing the JSON string. 
If deciding later to use relevancy weighting in the calculations, then the first occurence of the word should be used.

=end
