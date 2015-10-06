module ItunesSearch
  class Client

    MAX_TRIES = 5

    def initialize(proxies = nil, username = nil, password = nil)
      @proxies = proxies
      @username = username
      @password = password
    end

    def get_html(url)
      response = nil
      tries = 0
      begin
        if @proxies
          proxy = "http://#{@proxies.sample}"
          options = {}
          options[:proxy_http_basic_authentication] = [proxy, @username, @password]
          options[:ssl_verify_mode] = OpenSSL::SSL::VERIFY_NONE
        end
        obj = open(url, options)
        response = obj.read()
        Rails.logger.info('ItunesSearch get_html Success!')
      rescue => ex
        ex.backtrace.join("\n")
        if tries < MAX_TRIES
          tries += 1
          retry
        else
          raise ex
        end
      end
      response
    end


  end
end