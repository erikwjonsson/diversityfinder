class DataextractsController < ApplicationController
	require 'json'
	respond_to :html, :js

	def insert_apikey
		user_api_key = clean_params(params[:api_key])
		File.open("api_key.txt", 'w') {|f| f.write(user_api_key) }
		redirect_to :back
	end

	def delete_apikey
		File.open("api_key.txt", 'w') {|f| f.write('') }
		redirect_to :back
	end

	def index
		apikey_exists?
		choose_rebase_article(params[:dataextract])
		@dataextracts = Dataextract.all
	end

	def compare
		Dataextract.comparison_calculation
		redirect_to :controller => "dataextracts", :action => "index"
	end

	def rebase
		choose_rebase_article(params[:dataextract])
    respond_to do |format| format.js { render :template => "dataextracts/compare.js.erb", :layout => false } end
	end

	def new
		# REVIEW - ALSO NEED LINKCHECKER
		url = clean_params(params[:url])

		if Dataextract.exists?(url: url)
			puts "it exists"
		else
			puts "it does not exists"
			puts url
			Dataextract.query_alchemy(url)
				puts @keyword_entity_check
				puts @url
				puts @concepts_list
				puts @entities_list
			if @keyword_entity_check.length != 0 && @keyword_concept_check.length != 0
				Dataextract.create(url: url, concepts_list: @concepts_list, entities_list: @entities_list)
			elsif @keyword_entity_check.length == 0
				flash[:notice] = "Alchemy could not identify any ENTITY keywords. URL was not added to database!"
			elsif @keyword_concept_check.length == 0
				flash[:notice] = "Alchemy could not identify any CONCEPT keywords. URL was not added to database!"
			end
		end
		redirect_to :controller => "dataextracts", :action => "index"
	end

private

	def apikey_exists?
		File.read("api_key.txt").length == 40 ? (@api_key_status = 'API key present! You can now submit links!') : (@api_key_status = 'No API key present!')
	end

  def choose_rebase_article(article_id)
  	@rebase_id = article_id ? article_id.to_s[/\d+/].to_i : 1
  	return @rebase_id
  end

  def clean_params(params)
		still_dirty = params.to_s.gsub '["', ''
		cleaned_params = still_dirty.gsub '"]', ''
  	return cleaned_params
  end

end
