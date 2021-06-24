### UTILITY METHODS ###

When /^I view metadata for (.*)$/ do |view|
  visit "/views/#{View.find_by_name(view).id}"
end

When /^I view table for (.*)$/ do |view|
  visit "/views/#{View.find_by_name(view).id}/table"
end

Then /I should land on the (.*)/ do |pageType|
  case pageType
  when 'dashboard' 
      expect(page).to have_content "Catalog"
      expect(page).to have_content "Recent"
  when 'catalog'
      expect(page).to have_content "Catalog"
      expect(page).to_not have_content "Recent"
  when 'show view page'
      expect(page).to have_content "Description"
      expect(page).to have_content "Source"
      expect(page).to have_content "Metadata"
  when 'show table page'
    expect(page).to have_content "Table" # in breadcrumbs
  else
    pending "#{pageType} not implemented yet."
  end
end

Then /I should see a (.*) for (.*)$/ do |selector, name|
  expect(page).to have_selector(selector, visible: false)
  expect(page).to have_content name
end
  
