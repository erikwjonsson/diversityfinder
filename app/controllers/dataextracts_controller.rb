class DataextractsController < ApplicationController
	require './vendor/alchemyapi_ruby/alchemyapi'
	require 'json'
	respond_to :html, :js

	def index
		@dataextracts = Dataextract.all

		api_check = File.read("api_key.txt").length
		if api_check == 40
			@api_key_status = 'API key present! You can now submit links!'
		else
			@api_key_status = 'No API key present!'
		end

					#Difference.all.each do |p|
					#	p.destroy
					#end
	end

	def insert_apikey
		a = params[:api_key].to_s.gsub '["', ''
		@user_api_key = a.gsub '"]', ''
		File.open("api_key.txt", 'w') {|f| f.write(@user_api_key) }
		redirect_to :controller => "dataextracts", :action => "index"
	end

	def delete_apikey
		File.open("api_key.txt", 'w') {|f| f.write('') }
		redirect_to :controller => "dataextracts", :action => "index"
	end

	def compare
		if params[:dataextract].nil?
			@rebase_id = 1
		else
			@rebase_id = params[:dataextract].to_s[/\d+/].to_i
		end

		@dataextracts = Dataextract.all
			@master_array = Array.new
			@dataextracts.each do |p|
				if p.entities_list.present? && p.concepts_list.present? && p.url.present?

					# GET CONCEPTS AND ENITITES FOR ONE 
					# CONCEPTS
					concept_array = Array.new
					obj = JSON.parse(p.concepts_list)
					@concepts = obj['concepts']
					@concepts.each do |c|
						text = c['text']
						concept_array.push(text)
					end


					# ENTITIES
					entity_array = Array.new
					obj = JSON.parse(p.entities_list)
					@entities = obj['entities']
					@entities.each do |e|
						 text = e['text']
						entity_array.push(text)
					end


					url = Array.new
					url.push(p.url)

					data_destilled_array = Array.new
					data_destilled_array.push(url, entity_array, concept_array)

					
					@master_array.push(data_destilled_array)

						puts "----------VLADIMIR--------"
						puts concept_array

						puts "----------PUTIN--------"
						puts entity_array
				end
			end

			@master_array.each do |data_destilled_array| # Getting 
				@base_concepts = data_destilled_array[2].count # a base is picked and it's entities counted
				@base_array_concepts = data_destilled_array[2]
				@base_entities = data_destilled_array[1].count # a base is picked and it's entities counted
				@base_entities_array = data_destilled_array[1]

				@master_array.each do |d|

				#data_destilled_array.each do |d|

					@comparator_concepts = d[2].count # a comparator is chosen and its entities counted
					@comparator_concepts_array = d[2]
					@comparator_entities = d[1].count # a comparator is chosen and its entities counted
					@comparator_entities_array = d[1]

					@weight_concepts = 30.0
					@value_per_concept = 30.0 / @comparator_concepts
					@weight_entities = 30.0
					@value_per_entitity = 30.0 / @comparator_entities

					@base_array_concepts.each do |c| # check how many times word exists
						if @comparator_concepts_array.include? c
							@weight_concepts = @weight_concepts - @value_per_concept
						end
					end

					@base_entities_array.each do |c| # check how many times word exists
						if @comparator_entities_array.include? c
							@weight_entities = @weight_entities - @value_per_entitity
						end
					end

					d1 = Dataextract.where(:url => data_destilled_array[0]).first.id # base
					d2 = Dataextract.where(:url => d[0]).first.id # comparator
					if Difference.exists?(dataextraction1: d1, dataextraction2: d2) || d1 == d2
					else
						Difference.create(dataextraction1: d1, dataextraction2: d2, entities_diff: @weight_entities, concepts_diff: @weight_concepts)
					end
				#end
				end
		end
		redirect_to :controller => "dataextracts", :action => "index"
	end

	def rebase
		if params[:dataextract].nil?
			@rebase_id = 1
		else
			@rebase_id = params[:dataextract].to_s[/\d+/].to_i
		end

		@dataextracts = Dataextract.all

    respond_to do |format|
        format.js {
          render :template => "dataextracts/compare.js.erb",
          :layout => false
        }
    end
	end

	def new

		# REVIEW - ALSO NEED LINKCHECKER
		demo_url1 = params[:url].to_s.gsub '["', ''
		demo_url = demo_url1.gsub '"]', ''

		if Dataextract.exists?(url: demo_url)
		else
			alchemyapi = AlchemyAPI.new()

			myText = "I can't wait to integrate AlchemyAPI's awesome Ruby SDK into my app!"
			response = alchemyapi.sentiment("text", myText)
			puts "Sentiment: " + response["docSentiment"]["type"]


			entities_hash = Hash.new
			concepts_hash = Hash.new

			puts '############################################'
			puts '#   Entity Extraction Example              #'
			puts '############################################'
			puts ''
			puts ''

			puts 'Processing text: ' + demo_url
			puts ''

			response = alchemyapi.entities('url', demo_url, { 'sentiment'=>1 })

			if response['status'] == 'OK'
				puts '## Response Object ##'
				#puts JSON.pretty_generate(response)
				entities_list = JSON.pretty_generate(response)


				puts ''
				puts '## Entities ##'
				for entity in response['entities']
					puts 'text: ' + entity['text']
					puts 'type: ' + entity['type']
					puts 'relevance: ' + entity['relevance']
					print 'sentiment: ' + entity['sentiment']['type'] 
					
					#Make sure score exists (it's not returned for neutral sentiment
					if entity['sentiment'].key?('score')
						print ' (' + entity['sentiment']['score'] + ')'
					end

					puts ''
				end
			else
				puts 'Error in entity extraction call: ' + response['statusInfo']
			end


			puts ''
			puts ''
			puts ''
			puts '############################################'
			puts '#  Concept Tagging Example                 #'
			puts '############################################'
			puts ''
			puts ''

			puts 'Processing text: ' + demo_url
			puts ''

			response = alchemyapi.concepts('url', demo_url)

			if response['status'] == 'OK'
				puts '## Response Object ##'
				puts JSON.pretty_generate(response)
				concepts_list = JSON.pretty_generate(response)
				

				puts ''
				puts '## Concepts ##'
				for concept in response['concepts']
					puts 'text: ' + concept['text']
					puts 'relevance: ' + concept['relevance']
					puts ''
				end
			else
				#puts 'Error in concept tagging call: ' + response['statusInfo']
			end
			if concepts_list.present? && entities_list.present?
				Dataextract.create(url: demo_url, concepts_list: concepts_list, entities_list: entities_list)
			end
		end


		redirect_to :controller => "dataextracts", :action => "index"
	end

end
