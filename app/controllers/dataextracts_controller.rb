class DataextractsController < ApplicationController
	require './vendor/alchemyapi_ruby/alchemyapi'
	require 'json'
	respond_to :html, :js

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

	def index
		@rebase_id = params[:dataextract] ? params[:dataextract].to_s[/\d+/].to_i : 1
		@dataextracts = Dataextract.all
		File.read("api_key.txt").length == 40 ? (@api_key_status = 'API key present! You can now submit links!') : (@api_key_status = 'No API key present!')
	end

	def compare
		Dataextract.comparison_calculation
		redirect_to :controller => "dataextracts", :action => "index"
	end

	def rebase
		@rebase_id = params[:dataextract] ? params[:dataextract].to_s[/\d+/].to_i : 1
    respond_to do |format| format.js { render :template => "dataextracts/compare.js.erb", :layout => false } end
	end

	def new
		# REVIEW - ALSO NEED LINKCHECKER
		url1 = params[:url].to_s.gsub '["', ''
		url = url1.gsub '"]', ''

		if Dataextract.exists?(url: url)
		else
			alchemyapi = AlchemyAPI.new()

			# ======== Concept Tagging ========
			keyword_entity_check = Array.new
			keyword_concept_check = Array.new
			response = alchemyapi.entities('url', url, { 'sentiment'=>1 })
			if response['status'] == 'OK'
				entities_list = JSON.pretty_generate(response)
				for entity in response['entities']
					keyword_entity_check.push(entity['text'])
				end
			else
				puts 'Error in entity extraction call: ' + response['statusInfo']
			end

			# ======== Concept Tagging ========
			response = alchemyapi.concepts('url', url)
			if response['status'] == 'OK'
				concepts_list = JSON.pretty_generate(response)
				for concept in response['concepts']
					keyword_concept_check.push(concept['text'])
				end
			else
				puts 'Error in concept tagging call: ' + response['statusInfo']
			end

			if keyword_entity_check.length != 0 && keyword_concept_check.length != 0
				Dataextract.create(url: url, concepts_list: concepts_list, entities_list: entities_list)
			elsif keyword_entity_check.length == 0
				flash[:notice] = "Alchemy could not identify any ENTITY keywords. URL was not added to database!"
			elsif keyword_concept_check.length == 0
				flash[:notice] = "Alchemy could not identify any CONCEPT keywords. URL was not added to database!"
			end
		end
		redirect_to :controller => "dataextracts", :action => "index"
	end

end
