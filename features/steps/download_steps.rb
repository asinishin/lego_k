When(/^the service loaded the first page$/) do
  @page = LegoK::Api.first_page
  # p @page
end

Then(/^the page should contain filter "(.*?)" with value "(.*?)"$/) do |arg1, arg2|
  @page.search("##{arg1}").text.should eq(arg2)
end

Given(/^the last loaded listing: "(.*?)"$/) do |arg1|
  @page = LegoK::Api.first_page
  @last_loaded_listing = arg1
end

When(/^the service detected a page with new listings$/) do
  @new_listings = []
  loop do
    @new_listings = LegoK::Api.detect_new_listings(@page, @last_loaded_listing)
    if @new_listings.size > 0
      break
    else
      @page = LegoK::Api.next_page(@page)
      if @page.nil?
        break
      end
    end
  end
end

Then(/^the page should contain listing: "(.*?)"$/) do |arg1|
  #@new_listings.find { |e| e == arg1 }.should eq(arg1)
  @new_listings.should include(arg1)
end

When(/^the service detected a page with the listing: "(.*?)"$/) do |arg1|
  @listing_id = arg1
  @page = LegoK::Api.first_page
  loop do
    if LegoK::Api.detect_listing(@page, arg1)
      break
    else
      @page = LegoK::Api.next_page(@page)
      if @page.nil?
        break
      end
    end
  end
end

When(/^the service loaded the page with specified listing$/) do
  @page = LegoK::Api.load_listing_page(@page, @listing_id)
end

Then(/^the page should contain title: "(.*?)"$/) do |arg1|
  listing = LegoK::Api.parse_listing(@page)
  p listing[:title]
  p listing[:description]
  p listing[:rental_rate]
  address = LegoK::Api.parse_address(@page)
  p address[:address]
  p address[:latitude]
  p address[:longitude]
  LegoK::Api.load_photos(@listing_id)
end
