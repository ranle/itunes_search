require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'cgi'
require File.expand_path(File.dirname(__FILE__) + '/app_parser')

module ItunesSearch
  class Search
    attr_accessor :current_page, :category, :category_id, :category_letter, :next_page_number

    $ITUNES_BASE_URL = 'https://itunes.apple.com'

    ITUNES_BASE_CATEGORY_SEARCH_URL = $ITUNES_BASE_URL + '/us/genre/ios-'

    DEFAULT_SEARCH_CONDITION = {:language => 'en',
                                :category => 'apps',
                                #:per_page_num => 20,
                                :price => '0',
                                #:safe_search => "0",
                                :rating => '0'}

    def initialize(search_condition = DEFAULT_SEARCH_CONDITION)
      @search_condition = DEFAULT_SEARCH_CONDITION.merge(search_condition)

      @next_page_number = nil
      @current_page = 1
    end

    def search(data, options={})
      @category = data[:category]
      @category_id = data[:category_id]
      @category_letter = data[:category_letter]
	  if data[:current_page].present?
		@next_page_number = data[:current_page]
	  end
      html = open(init_query_url, {:ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE}).read()
      # p html.html_safe
      itunes_html = Nokogiri::HTML(html)
      get_next_page_number(itunes_html)
      AppParser.new(html).parse
    end

    def next_page
      @current_page += 1
      data = {
          :category => @category,
          :category_id => @category_id,
          :category_letter => @category_letter
      }
      search data
    end

    private
    def init_query_url
      query_url = ''
      query_url << ITUNES_BASE_CATEGORY_SEARCH_URL
      query_url << CGI.escape(@category).downcase << '/'

      if @category_id
        query_url << @category_id
      end
      if @category_letter
        # query_url << "?letter=#{@category_letter}"
        query_url << "?letter=#{@category_letter}"
        if @next_page_number
          query_url << "&page=#{@next_page_number}"
        end
      elsif @next_page_number
          query_url << "?page=#{@next_page_number}"
      end

      query_url
    end

    def get_next_page_number(response_body)
      number = response_body.search('.paginate-more').first
      if number.blank?
        nil
        return
      end

      number = number['href'].match(/page=(.+?)#/)[1]
      Rails.logger.info("Scan page: ##{number}, category: #{@category}, letter: #{@category_letter}")
      if number == @next_page_number
        raise 'EndOfScan'
      else
        @next_page_number = number.to_i
      end
      @next_page_number.to_i
    end

  end
end