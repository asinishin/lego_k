require 'rubygems'
require 'mechanize'

module LegoK

  BASE_URL    = ENV['LEGOK_BASE_URL']
  BASE_PHOTOS = ENV['LEGOK_BASE_PHOTOS']

  class Api

    def self.instance
      @@api_agent ||= Api.new
    end

    def agent
      @agent ||= Mechanize.new
    end

    def first_page # opens the first page of default category
      page = agent.get(BASE_URL + '/')
      page = page.links.find { |l| l.text == 'storage, parking' }.click
      page.links.find { |l| l.text == "\r\nPosted\r\n" }.click # Change sorting order
    end

    def next_page(current_page) # moves to the next page
      current_page.links_with(:class => "prevNextLink").each do |link|
	if link.text.include?('Next')
	  return link.click
	end
      end
      nil
    end

    # Low level methods of operating with listings within a page
    def detect_new_listings(page, last_loaded_listing_id) # returns ids of appropirated listings or []
      ids = page.search("input[name='ilIds']").first.attr('value').split(',')
      ids.inject([]) do |r, e|
        if e > last_loaded_listing_id
	  r << e
	else
	  r
	end
      end
    end

    def detect_listing(page, listing_id)
      page.search("input[name='ilIds']").first.attr('value').split(',').include?(listing_id)
    end

    def load_listing_page(page, listing_id)
      node = page
        .search("div[class='#{listing_id}']")
	.first.parent.parent.parent
	.children.css("td a.adLinkSB").first
      if node
	Mechanize::Page::Link.new(node, agent, page).click
      end
    end

    def load_photos(listing_id)
      ix = 0
      loop do
	page = agent.get(BASE_URL + '/c-ViewAdLargeImage?AdId=' + listing_id + '&ImageIndex=' + ix.to_s)
	pgr = page.search("td#pager")
	if pgr.size > 0
	  pgr = pgr.text.split(' / ')
	end
	image_nodeset = page.search("img#LargeImage")
	if image_nodeset.size == 0
	  break
	else
	  image_url = image_nodeset.attr('src')
	  agent.get(image_url).save_as(BASE_PHOTOS + "p#{listing_id}#{ix}.jpg")
	  ix += 1
	  if pgr.size == 0 || (pgr.size == 2 && pgr[0] == pgr[1]) || ix > 8 
	    break
	  end
	end
      end
    end

    # Methods for parsing a listing
    def parse_listing(page, listing_id)
      {
	title:          extract_title(page),
	description:    parse_description(page),
	space_type_id:  1,
	length:         1.0,
	width:          1.0,
	height:         1.0,
	is_for_vehicle: false,
	is_small_transport: false,
	is_large_transport: false,
	rental_rate:    parse_rate(page),
	surface_id:     1,
	rental_term_id: 1,
	is_no_height:   false,
	source_site:    'kj',
	source_id:      listing_id
      }
    end

    def listing_filter(listing)
      return false if listing[:title].upcase.include?('WANTED')
      true
    end

    def address_filter(address)
      return false if address[:zip_code].nil?
      return false if address[:zip_code].size == 0
      return false if address[:zip_code].size > 15
      return false if address[:latitude].nil? || address[:longitude].nil?
      true
    end

    def parse_address(page)
      s = extract_address(page)
        .split("\r\n")[0]
	.split(',')
	.map { |e| e.strip }
	.reject { |e| ['Toronto', 'Canada'].include?(e) }
      if s.size > 2
        addr     = s[0]
	city     = s[1]
	zip_code = s[2]
      elsif s.size > 1
        addr     = s[0]
	city     = 'Toronto'
	zip_code = s[1]
      elsif s.size > 0
        addr     = '-'
	city     = 'Toronto'
	zip_code = s[0]
      else
        addr     = nil
	city     = nil
	zip_code = nil
      end
      if zip_code
	zip_code = zip_code.split(' ')
	  .reject { |e| e == 'ON' }
	  .join(' ')
      end
      lat = nil
      lng = nil
      page.links_with(:class => "viewmap-link").each do |link|
        map_page = link.click
	lat_node = map_page.search("meta[property='og:latitude']").first
	if lat_node
	  lat = lat_node.attr('content')
	end
	lng_node = map_page.search("meta[property='og:longitude']").first
	if lng_node
	  lng = lng_node.attr('content')
	end
      end
      {
	address:        addr,
	city:           city,
	state_province: 'ON',
	zip_code:       zip_code,
	country_id:     1,
	latitude:       lat,
	longitude:      lng
      }    
    end

    def extract_title(page)
      s = page.search("h1#preview-local-title").text
      return s[0..49] if s.size > 50
      s
    end

    def extract_address(page)
      extract_table_value(page, 'Address')
    end

    def parse_description(page)
      page.search("div#ad-desc")
        .first.children
	.css("span")
	.text.strip
    end

    def parse_rate(page)
      s = extract_table_value(page, 'Price').sub('$', '')
      if is_a_number?(s)
        s
      else
        "51.00"
      end
    end

    def is_a_number?(s)
      s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true
    end

    def extract_table_value(page, title)
      row = page.search("table#attributeTable")
        .first.children
	.css("tr:contains('#{title}')")
	.first
      if row
	row.children
	  .css("td")
	  .last.text.strip
      else
        " \r\n" # Return an empty address
      end
    end

  end

end
