require 'open-uri'
require 'nokogiri'
require File.expand_path(File.dirname(__FILE__) + '/review')

module ItunesSearch
  class App

    attr_accessor :id, :name, :url, :category, :logo_url,
                  :short_description, :rating, :reviews, :price,
                  :version, :installs, :last_updated, :size,
                  :requires_android, :content_rating, :developer, :developer_website,
                  :developer_email, :developer_address, :screenshots,
                  :long_description, :reviews_count

    def get_all_details(options={}, proxies=[], username=nil, password=nil)
      html = self.get_html options, proxies, username, password
      itunes_html = Nokogiri::HTML(html)

      # self.version = get_version(itunes_html)
      # self.last_updated = get_last_updated(itunes_html)
      # self.size = get_size(itunes_html)
      self.content_rating = get_content_rating(itunes_html)
      self.category = get_category(itunes_html)
      self.developer = get_developer(itunes_html)
      self.developer_website = get_developer_website(itunes_html)
      self.reviews_count = get_reviews_count(itunes_html)

      # self.installs = get_installs(itunes_html)
      # self.requires_android = get_requires_android(itunes_html)
      # self.developer_email = get_developer_email(itunes_html)
      # self.developer_address = get_developer_address(itunes_html)
      # self.reviews = get_reviews(itunes_html)
      # self.screenshots = get_screenshots(itunes_html)
      # self.long_description = get_long_description(itunes_html)
      self
    rescue => e
      if Rails.env.production?
        NewRelic::Agent.notice_error(e)
      end
      puts e.backtrace.join("\n")
      self
    end

    def get_html(options={}, proxies=[], username=nil, password=nil)
      response = proxy = nil
      success = false

      if proxies.present?
        proxy = "http://#{proxies.sample}"
        options[:proxy_http_basic_authentication] = [proxy, username, password]
      end

      while !success
        begin
          response = open(self.url, options).read()
          success = true
        rescue OpenURI::HTTPError => ex
          p "Error! #{ex.io.status[0]}: #{ex.io.status[1]} (proxy: #{proxy}"
          if Rails.env.production?
            NewRelic::Agent.notice_error("Error! #{ex.io.status[0]}: #{ex.io.status[1]} (proxy: #{proxy}")
          end
          proxy = "http://#{proxies.sample}"
          options[:proxy_http_basic_authentication] = [proxy, username, password]
        end
      end
      response
    end

    private

    def get_version(itunes_html)
      version = itunes_html.search("[itemprop=softwareVersion]").first
      version.content.strip if version
    end

    def get_last_updated(itunes_html)
      last_updated = itunes_html.search("[itemprop=datePublished]").first
      last_updated.content.strip if last_updated
    end

    def get_installs(itunes_html)
      ''
    end

    def get_size(itunes_html)
      size = itunes_html.at('li:contains("Size:")')
      size.text.strip.gsub('Size: ', '').gsub(' MB', '') if size
    end

    def get_requires_android(itunes_html)
      requires_android = itunes_html.search("div[itemprop='operatingSystems']").first
      requires_android.content.strip if requires_android
    end

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
      itunes_html.search('.app-links a').first['href']
    end

    def get_developer_email(itunes_html)
      itunes_html.search("a[class='dev-link']").each do |ele|
        return ele.content.strip.gsub("Email ", "") if ele.content.strip.index("Email")
      end
    end

    def get_developer_address(itunes_html)
      address = itunes_html.search("div[class='content physical-address']").first
      address.content.strip if address
    end

    def get_long_description(itunes_html)
      long_description = itunes_html.search("div[class='id-app-orig-desc']").first
      long_description.content.strip if long_description
    end

    def get_reviews(itunes_html)
      reviews = []
      itunes_html.search("div[class='single-review']").each do |ele|
        review = ItunesSearch::Review.new()
        review.author_name = ele.search("span[class='author-name']").first.content.strip
        review.author_avatar = ele.search("img[class='author-image']").first['src'].strip
        review.review_title = ele.search("span[class='review-title']").first.content.strip
        review.review_content = ele.search("div[class='review-body']").children[2].content.strip
        review.star_rating = ele.search("div[class='tiny-star star-rating-non-editable-container']").first['aria-label'].scan(/\d/).first.to_i
        reviews << review
      end
      reviews
    end

    def get_reviews_count(itunes_html)
      get_reviews = itunes_html.search('div.rating').last
      get_reviews.content.strip.gsub(/\D/, '') if get_reviews
    end

    def get_screenshots(itunes_html)
      screenshots = []
      itunes_html.search("div[class='screenshot-align-inner'] img").each do |ele|
        screenshots << ele['src'].strip
      end
      screenshots
    end

  end

end