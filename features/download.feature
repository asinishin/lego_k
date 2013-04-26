@given_listings

Feature: Listing dowloader
  In case to be a proud hacker
  An owner of the service
  Wants to scrap all Nobel laureats from Wiki

  Scenario: Service loaded the first page of storage category
  When the service loaded the first page
  Then the page should contain filter "catbox" with value "storage, parking"

  Scenario: Service found a page with new listings
  Given the last loaded listing: "460379560"
  When the service detected a page with new listings
  Then the page should contain listing: "460439158"

  Scenario: Service loaded a page with the specified listing
  When the service detected a page with the listing: "460379560"
  And  the service loaded the page with specified listing
  Then the page should contain title: "doiuble garage"
