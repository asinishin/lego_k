require 'rubygems'
require 'mechanize'

module LegoK

  BASE_URL    = ENV['LEGOK_BASE_URL']
  BASE_PHOTOS = ENV['LEGOK_BASE_PHOTOS']

  class Api

    def self.agent
      @@agent ||= Mechanize.new
    end

    def self.download_next_listing(last_loaded_listing_id)
    end
    
    # Low level methods of pages navigation
    def self.first_page # opens the first page of default category
      page = agent.get(BASE_URL + '/')
      page = page.links.find { |l| l.text == 'storage, parking' }.click
      page.links.find { |l| l.text == "\r\nPosted\r\n" }.click # Change sorting order
    end

    def self.next_page(current_page) # moves to the next page
      link = current_page.link_with(:class => "prevNextLink")
      if link && link.text.include?('Next')
        link.click
      else
        nil
      end
    end

    # Low level methods of operating with listings within a page
    def self.detect_new_listings(page, last_loaded_listing_id) # returns ids of appropirated listings or []
      ids = page.search("input[name='ilIds']").attr('value').value.split(',')
      ids.inject([]) do |r, e|
        if e.to_i > last_loaded_listing_id.to_i
	  r << e
	else
	  r
	end
      end
    end

    def self.detect_listing(page, listing_id)
      page.search("input[name='ilIds']").attr('value').value.split(',').include?(listing_id)
    end

    def self.load_listing_page(page, listing_id)
      node = page
        .search("div[class='#{listing_id}']")
	.first.parent.parent.parent
	.children.css("td a.adLinkSB").first
      if node
	Mechanize::Page::Link.new(node, agent, page).click
      end
    end

    def self.load_photos(listing_id)
      FileUtils.rm_rf(Dir.glob(BASE_PHOTOS + '*'))
      ix = 0
      loop do
	page = agent.get(BASE_URL + '/c-ViewAdLargeImage?AdId=' + listing_id + '&ImageIndex=' + ix.to_s)
	pgr = page.search("td#pager").text.split(' / ')
	image_nodeset = page.search("img#LargeImage")
	if image_nodeset.size == 0
	  break
	else
	  image_url = image_nodeset.attr('src')
	  agent.get(image_url).save_as(BASE_PHOTOS + "p#{listing_id}_#{ix}.jpg")
	  ix += 1
	  if (pgr.size == 2 && pgr[0] == pgr[1]) || ix > 5
	    break
	  end
	end
      end
    end

    # Methods for parsing a listing
    def self.parse_listing(page, listing_id)
      {
	title:          page.search("h1#preview-local-title").text,
	description:    Api::parse_description(page),
	space_type_id:  1,
	length:         1.0,
	width:          1.0,
	height:         1.0,
	is_for_vehicle: false,
	is_small_transport: false,
	is_large_transport: false,
	rental_rate:    Api::parse_rate(page),
	surface_id:     1,
	rental_term_id: 1,
	is_no_height:   false,
	source_site:    'kj',
	source_id:      listing_id
      }
    end

    def self.filter(listing, address)
      return false if listing[:title].upcase.include?('WANTED')
      return false if address[:zip_code].size > 15
      true
    end

    def self.parse_address(page)
      s = Api::extract_address(page)
        .split("\r\n")[0]
	.split(',')
	.map { |e| e.strip }
	.reject { |e| ['Toronto', 'Canada'].include?(e) }
      if s.size > 1
        addr     = s[0]
	zip_code = s[1]
      else
        addr     = '*'
	zip_code = s[0]
      end
      zip_code = zip_code.split(' ')
        .reject { |e| e == 'ON' }
	.join(' ')
      map_page = page.link_with(:class => "viewmap-link").click
      lat = map_page.search("meta[property='og:latitude']").first.attr('content')
      lng = map_page.search("meta[property='og:longitude']").first.attr('content')
      {
	address:        addr,
	city:           'Toronto',
	state_province: 'ON',
	zip_code:       zip_code,
	country_id:     1,
	latitude:       lat,
	longitude:      lng
      }    
    end

    def self.extract_address(page)
      Api::extract_table_value(page, 'Address')
    end

    def self.parse_description(page)
      page.search("div#ad-desc")
        .first.children
	.css("span")
	.text.strip
    end

    def self.parse_rate(page)
      Api::extract_table_value(page, 'Price')
    end

    def self.extract_table_value(page, column)
      page.search("table#attributeTable")
        .first.children
	.css("tr:contains('#{column}')")
	.first.children
	.css("td")
	.last.text.strip
    end

  end

end
