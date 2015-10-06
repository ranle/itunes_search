require 'open-uri'
require 'nokogiri'
require File.expand_path(File.dirname(__FILE__) + '/review')
require File.expand_path(File.dirname(__FILE__) + '/client')

module ItunesSearch
  class App

    attr_accessor :id, :name, :url, :category, :logo_url,
                  :short_description, :rating, :reviews, :price,
                  :version, :installs, :last_updated, :size,
                  :requires_android, :content_rating, :developer, :developer_website,
                  :developer_email, :developer_address, :screenshots,
                  :long_description, :reviews_count

    def get_all_details
      html = ItunesSearch.get_client.get_html(self.url)
      itunes_html = Nokogiri::HTML(html)

      self.content_rating = get_content_rating(itunes_html)
      self.category = get_category(itunes_html)
      self.developer = get_developer(itunes_html)
      self.developer_website = get_developer_website(itunes_html)
      self.reviews_count = get_reviews_count(itunes_html)
      self

    end

    private

    def get_content_rating(itunes_html)
      content_rating = itunes_html.search('div.rating').last
      content_rating.content.strip.gsub(/\D/, '') if content_rating
    end

    def get_category(itunes_html)
      category = itunes_html.search('.genre').last
      category.content.strip.gsub('Category: ', '') if category
    end

    def get_developer(itunes_html)
      dev_name = itunes_html.search('[itemprop=name]').last
      dev_name.content.strip if dev_name
    end

    def get_developer_website(itunes_html)
      result = itunes_html.search('.app-links a')
      if result.present?
        result = result.first['href']
      end
      result
    end

    def get_developer_email(itunes_html)
      itunes_html.search("a[class='dev-link']").each do |ele|
        return ele.content.strip.gsub('Email ', '') if ele.content.strip.index('Email')
      end
    end

    def get_developer_address(itunes_html)
      address = itunes_html.search("div[class='content physical-address']").first
      address.content.strip if address
    end

    def get_reviews_count(itunes_html)
      get_reviews = itunes_html.search('div.rating-count').last
      if !(has_digits?(get_reviews.to_s))
        get_reviews = itunes_html.search('[itemprop=reviewCount]').last
        if !(has_digits?(get_reviews.to_s))
          get_reviews = nil
        end
      end
      get_reviews.content.strip.match(/\d+/)[0] if get_reviews
    end

    def get_screenshots(itunes_html)
      screenshots = []
      itunes_html.search("div[class='screenshot-align-inner'] img").each do |ele|
        screenshots << ele['src'].strip
      end
      screenshots
    end

    def has_digits?(str)
      result = false
      if !str.nil?
        result = str.count('0-9') > 0
      end
      result
    end

  end

end