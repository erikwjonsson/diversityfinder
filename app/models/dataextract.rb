require './vendor/alchemyapi_ruby/alchemyapi'

class Dataextract < ActiveRecord::Base

	def self.comparison_calculation # Calculates the differences between all articles against all other articles based on entity and concept keywords.
		extracted_keywords_and_urls = self.keyword_and_url_extraction
		extracted_keywords_and_urls.each do |base_article_data| # Loops through each article data set to declare as base.
			base_entities = base_article_data[1][:entities] # a base for entities keywords is chosen.
			base_concepts = base_article_data[1][:concepts] # a base for concept keywords is chosen.

			Dataextract.where(:url => base_article_data[1][:url]).first.update_columns(conceptkeywords: base_concepts.to_s, entitykeywords: base_entities.to_s)

			#base_type_keywords = [base_entities, base_concepts]
			base_type_keywords = {:entities => base_entities, :concepts => base_concepts}

			extracted_keywords_and_urls.each do |comparator_article_data| # Loops through each article data set to declare as comparator.
				
				base_type_keywords.each do |type, keywords|
					comparator_keywords = comparator_article_data[1][:"#{type}"]
					total_weight = 30.0
					weight_per_keyword = total_weight / comparator_keywords.count
					self.console_output_start("#{type}", base_article_data[1][:url], base_type_keywords, comparator_article_data[1][:url], comparator_keywords, total_weight, weight_per_keyword)
					
					keywords.each do |keyword| # check how many times concept keyword exists and detract weight if found.
						condition = comparator_keywords.include? keyword
						condition ? (total_weight = total_weight - weight_per_keyword) : total_weight
						condition ? (puts keyword + "   #{total_weight}") : ""
					end

					(self.console_output_zero(total_weight) && total_weight = 0) if total_weight < 0 # If total weight below zero, set to zero.
					@total_weight_entities = total_weight if type == 'entities'
					@total_weight_concepts = total_weight if type == 'concepts'
					self.console_output_ending(total_weight)
				end

				base_article_id = Dataextract.where(:url => base_article_data[1][:url]).first.id
				comparator_article_id = Dataextract.where(:url => comparator_article_data[1][:url]).first.id
				if Difference.exists?(dataextraction1: base_article_id, dataextraction2: comparator_article_id) || base_article_id == comparator_article_id
				else
					Difference.create(dataextraction1: base_article_id, dataextraction2: comparator_article_id, entities_diff: @total_weight_entities, concepts_diff: @total_weight_concepts)
				end
			end
		end
	end

	def self.keyword_and_url_extraction # Parses the JSON strings from Alchemy stored in the database.
		extracted_keywords_and_urls = Hash.new
		self.all.each do |p|
			if self.check_not_empty?(p) == true
				entity_keywords = self.parse_json_for_keywords('entities', p)
				concept_keywords = self.parse_json_for_keywords('concepts', p)
				article_data = {:url => p.url, :entities => entity_keywords, :concepts => concept_keywords}
				extracted_keywords_and_urls[p.id] = article_data # pushes hash to master hash
			end
		end
		return extracted_keywords_and_urls
	end

	def self.parse_json_for_keywords(keyword_type, dataextract) # Valid keywordtypes: 'concepts' and 'entities'
		#puts "REVELATOR"
		#concepts.each {|c| (puts c['text'] + "#{c['relevance']}" )}
		keywords = Array.new
		JSON.parse(dataextract.send("#{keyword_type}_list"))["#{keyword_type}"].each {|e| keywords.push(e['text'])}
		keywords = keywords.uniq # Read more below #1
		return keywords
	end

	def self.check_not_empty?(p)
	condition = p.entities_list.present? && p.concepts_list.present? && p.url.present?
	condition ? (return true) : (return false)
	end

	def self.console_output_start(type, base_article_url, base_keywords, comparator_article_url, comparator_keywords, total_weight, weight_per_keyword)
		puts "=================== # CALCULATOR #{type} # ==================="
		puts ""
		puts "FIRST URL"
		puts base_article_url
		puts ""
		print base_keywords
		puts ""
		puts "Number of entitiy keywords in base:"
		puts base_keywords.count
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

	def self.console_output_zero(total_weight)
		puts "====== !!!!!! SUB-ZERO !!!!!! ======"
		puts ""
		puts total_weight
		puts ""
		puts "EQALIZED TO ZERO ===> 0"
		puts ""
	end

	def self.console_output_ending(total_weight)
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

	def self.query_alchemy(url)
		if Dataextract.exists?(url: url)
		else
			alchemyapi = AlchemyAPI.new()
			# ======== Concept Tagging ========
			@keyword_entity_check = Array.new
			@keyword_concept_check = Array.new
			response = alchemyapi.entities('url', url, { 'sentiment'=>1 })
			if response['status'] == 'OK'
				@entities_list = JSON.pretty_generate(response)
				for entity in response['entities']
					@keyword_entity_check.push(entity['text'])
				end
			else
				puts 'Error in entity extraction call: ' + response['statusInfo']
			end
			# ======== Concept Tagging ========
			response = alchemyapi.concepts('url', url)
			if response['status'] == 'OK'
				@concepts_list = JSON.pretty_generate(response)
				for concept in response['concepts']
					@keyword_concept_check.push(concept['text'])
				end
			else
				puts 'Error in concept tagging call: ' + response['statusInfo']
			end
			if @keyword_entity_check.length != 0 && @keyword_concept_check.length != 0
				Dataextract.create(url: url, concepts_list: @concepts_list, entities_list: @entities_list)
			elsif @keyword_entity_check.length == 0
				flash[:notice] = "Alchemy could not identify any ENTITY keywords. URL was not added to database!"
			elsif @keyword_concept_check.length == 0
				flash[:notice] = "Alchemy could not identify any CONCEPT keywords. URL was not added to database!"
			end
		end
	end
end


=begin

========================ISSUES=======================

a. 	For some reason when comparing the same article againt itself it flips out in the last part of the loop.
		It removes to much weight so it becomes below zero.
		SUGGESTED SOLUTION: Not calculating the difference between itself is not needed. Ask it to skip.


#1 Removes dublicate keywords which Alchemy might output

Alchemy seems to have issues with some links. 
It puts the exact same keyword several times, but seemt to think it is different things.
Example https://en.wikipedia.org/wiki/Panama_Papers
In the example Alchemy says "Mossack Fonseca" is a Person, City, Company and GeographicFeature.
So the keyword "Mossack Fonseca" appears four times.'

SUGGESTED SOLUTION: 
Remove duplicates when parsing the JSON string. 
If deciding later to use relevancy weighting in the calculations, then the first occurence of the word should be used.

=end