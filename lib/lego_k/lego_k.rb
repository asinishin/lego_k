require 'rubygems'
require 'mechanize'

module LegoK

  BASE_URL    = "http://toronto.kijiji.ca" #ENV['LEGOK_BASE_URL']
  BASE_PHOTOS = "photos/"                  #ENV['LEGOK_BASE_PHOTOS']

  class Api

    def self.agent
      @@agent ||= Mechanize.new
    end

    def self.download_next_listing(last_listing_id)
    end
    
    # Low level methods of pages navigation
    def self.first_page # opens the first page of default category
      page = agent.get(BASE_URL + '/')
      page.links.find { |l| l.text == 'storage, parking' }.click
      page.links.find { |l| l.text == ' Posted ' }.click # Change sorting order
    end

    def self.next_page(current_page) # moves to the next page
      link = current_page.links.find { |l| l.text == 'Next >' }
      if link
        link.click
      end
    end

    # Low level methods of operating with listings within a page
    def self.detect_listing(page, last_listing_id) # returns id of appropirated listing or nil
      
    end

    def self.load_listing(page, listing_id)
    end

    def self.load_photo(page, photo_id)
    end

  end

end
