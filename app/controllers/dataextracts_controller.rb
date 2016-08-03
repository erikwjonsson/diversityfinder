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
		Dataextract.create_alchemy_extract(url)
		redirect_to :controller => "dataextracts", :action => "index"
	end

private

	def apikey_exists?
		File.read("api_key.txt").length == 40 ? (@api_key_status = 'API key present! You can now submit links!') : (@api_key_status = 'No API key present!')
	end

  def choose_rebase_article(article_id)
		puts "PARAMS------"
  	@rebase_id = article_id.nil? ? 1 : article_id.to_s[/\d+/].to_i
  	puts @rebase_id
  	return @rebase_id
  end

  def clean_params(params)
		still_dirty = params.to_s.gsub '["', ''
		cleaned_params = still_dirty.gsub '"]', ''
  	return cleaned_params
  end

end
