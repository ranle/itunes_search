require 'itunes_search/version'
require 'itunes_search/search'
require 'itunes_search/client'
module ItunesSearch

  @client = nil

  def self.build_http_client(options)
    @client = ItunesSearch::Client.new(options[:proxies], options[:username], options[:password])
  end

  def self.get_client
    if @client.nil?
      @client = ItunesSearch::Client.new
    end
    @client
  end

end
