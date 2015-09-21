module ItunesSearch
  class Railtie < Rails::Railtie
  end
end

# lib/my_gem.rb
require 'itunes_search/railtie' if defined?(Rails)