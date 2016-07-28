class Dataextract < ActiveRecord::Base

	def self.keyword_and_url_extraction # Parses the JSON strings from Alchemy stored in the database.
		@extracted_keywords_and_urls = Hash.new
		self.all.each do |p|
			if p.entities_list.present? && p.concepts_list.present? && p.url.present?
				concept_keywords = Array.new
				#puts "REVELATOR"
				#concepts.each {|c| (puts c['text'] + "#{c['relevance']}" )}
				JSON.parse(p.concepts_list)['concepts'].each {|c| concept_keywords.push(c['text'])}
				concept_keywords = concept_keywords.uniq # Read more below #1

				entity_keywords = Array.new
				JSON.parse(p.entities_list)['entities'].each {|e| entity_keywords.push(e['text'])}
				entity_keywords = entity_keywords.uniq # Read more below #1
				hash = Hash.new
				hash = {:url => p.url, :entities => entity_keywords, :concepts => concept_keywords}
				
				@extracted_keywords_and_urls[p.id] = hash # pushes hash to master hash
			end
		end
		return @extracted_keywords_and_urls
	end

	def self.comparison_calculation # Calculates the differences between all articles against all other articles based on entity and concept keywords.
		extracted_keywords_and_urls = self.keyword_and_url_extraction
		extracted_keywords_and_urls.each do |base_article_data| # Loops through each article data set to declare as base.
			base_entities = base_article_data[1][:entities] # a base for entities keywords is chosen.
			base_concepts = base_article_data[1][:concepts] # a base for concept keywords is chosen.

			extracted_keywords_and_urls.each do |comparator_article_data| # Loops through each article data set to declare as comparator.
				comparator_entities = comparator_article_data[1][:entities] # a comparator for concepts keywords is chosen.
				comparator_concepts = comparator_article_data[1][:concepts] # a comparator for entities keywords is chosen.

				total_weight_concepts = 30.0
				total_weight_entities = 30.0
				weight_per_concept = total_weight_concepts / comparator_article_data[1][:concepts].count
				weight_per_entitity = total_weight_entities / comparator_article_data[1][:entities].count

				self.write_console_output_entities(base_article_data[1][:url], base_concepts, comparator_article_data[1][:url], comparator_concepts, total_weight_concepts, weight_per_concept)

				base_concepts.each do |concept_keyword| # check how many times concept keyword exists and detract weight if found.
					condition = comparator_concepts.include? concept_keyword
					condition ? (total_weight_concepts = total_weight_concepts - weight_per_concept) : total_weight_concepts
					condition ? (puts concept_keyword + "   #{total_weight_concepts}") : ""
				end
				if total_weight_concepts < 0
					self.write_console_output_entities_zero(total_weight_concepts)
					total_weight_concepts = 0
				end

				self.write_console_output_entities_ending(total_weight_concepts)

				self.write_console_output_entities(base_article_data[1][:url], base_entities, comparator_article_data[1][:url], comparator_entities, total_weight_entities, weight_per_entitity)

				base_entities.each do |entity_keyword| # check how many times concept keyword exists and detract weight if found.
					condition = comparator_entities.include? entity_keyword
					condition ? (total_weight_entities = total_weight_entities - weight_per_entitity) : total_weight_entities
					condition ? (puts entity_keyword + "   #{total_weight_entities}") : ""
				end
				if total_weight_entities < 0
					self.write_console_output_entities_zero(total_weight_entities)
					total_weight_entities = 0
				end

				self.write_console_output_entities_ending(total_weight_entities)

				base_article_id = Dataextract.where(:url => base_article_data[1][:url]).first.id
				comparator_article_id = Dataextract.where(:url => comparator_article_data[1][:url]).first.id
				if Difference.exists?(dataextraction1: base_article_id, dataextraction2: comparator_article_id) || base_article_id == comparator_article_id
				else
					Difference.create(dataextraction1: base_article_id, dataextraction2: comparator_article_id, entities_diff: total_weight_entities, concepts_diff: total_weight_concepts)
				end
			end
		end
	end

	def self.write_console_output_entities(base_article_url, base_keywords, comparator_article_url, comparator_keywords, total_weight, weight_per_keyword)
		puts "=================== # CALCULATOR CONCEPTS # ==================="
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

	def self.write_console_output_entities_zero(total_weight)
		puts "====== !!!!!! SUB-ZERO !!!!!! ======"
		puts ""
		puts total_weight
		puts ""
		puts "EQALIZED TO ZERO ===> 0"
		puts ""
	end

	def self.write_console_output_entities_ending(total_weight)
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