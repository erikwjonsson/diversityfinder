require 'feedjira' # http://feedjira.com - Parses RSS feeds
require 'open-uri' # To open URLs and send REST requests
require 'json'

demo_url = 'https://www.theguardian.com/news/2016/apr/03/the-panama-papers-how-the-worlds-rich-and-famous-hide-their-money-offshore'
concepts_list = 'blabla bla bla'
Word.create(url: demo_url, entity_list: concepts_list)
