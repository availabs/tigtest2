### UTILITY METHODS ###

def add_source(name)
  return FactoryGirl.create(:source, name: name, user: @user)
end

def actions_menu
  find(:css, "#actionsMenu")
end

### GIVEN ###
Given(/^I have a catalog with multiple sources and views$/) do
  @user = create_user

  @source1 = add_source("Source A")
  @source1.add_view("View a")
  @source1.add_view("View b")
  @source1.update_attributes(:origin_url => "http://camsys.com")
  @source2 = add_source("Source B")
  @source2.add_view("View c")
  @source2.add_view("View d")

  Action.find_or_create_by(name: 'metadata')
  @source1.views[0].add_action(:metadata)
  @source1.views[1].add_action(:metadata)
  @source2.views[0].add_action(:metadata)
  @source2.views[1].add_action(:metadata)

  FactoryGirl.create(:access_control, source: @source1)
  FactoryGirl.create(:access_control, source: @source2)
end

Given(/^I have opened the Catalog$/) do
  visit '/sources'
end

Given /^Actions exist$/ do
  Action.find_or_create_by(name: 'table')
  Action.find_or_create_by(name: 'map')

  viewB = @source1.views[1]
  viewB.add_action(:table)

  @source2.views[0].add_action(:map)
  @source2.views[0].add_action(:table)
  @source2.views[1].add_action(:table)
end

### WHEN ###
When(/^I select the Catalog from the Dashboard$/) do
  click_link "Catalog"
end

When(/^I open source (.*)$/) do |source|
  find('h4', text: source).click
end

When /^I (?:go||select the||select action:) (.*)$/ do |name|
  click_link name
end

When /^I choose (.*)$/ do |name|
  sleep 1
  click_button name
end

When /^I  first (.*)$/ do |name|
  page.first(:link, name).click
end

When /^I select (.*) for Source(.*)$/ do |action, name|
  click_link_or_button '#Source' + name
  click_link_or_button action
end

When /^I select (.*) for View(.*)$/ do |action, name|
  click_link_or_button 'View' + name
  click_link_or_button action
end

### THEN ###
Then(/^I should see the Catalog tree$/) do
  expect(page).to have_content "Source A"
  expect(page).to have_content "Source B"
  not page.first('li', :text => "View a").visible?
  not page.first('li', :text => "View c").visible?
end

Then(/^I should see view (.*)$/) do |view|
  page.first('li', :text => view ).visible?
end

Then /^I should see link to (.*)$/ do |link|
  expect(page).to have_link link, :href => link
end

Then /^(.*) should be selected$/ do |name|
  expect(page).to have_css "button:focus"
  expect(find(:css, "button:focus")).to have_content name
end

Then(/^I should see the (.*) Menu$/) do |name|
  expect(page).to have_content(name)
end

Then(/^I should not see any available actions$/) do
  actions_menu.all('li').each do |item|
    assert (item[:class] == 'nav-header' || item[:class] == 'disabled') unless item[:class].nil?
  end
end

Then(/^I should see the (.*) action available$/) do |name|
  expect(actions_menu).to have_link name
  expect(actions_menu).to_not have_css('li.disabled', :text => name)
end

Then /^I should see columns for (.*)$/ do |name|
  view = View.find_by(name: name)
  expect(view.columns).to eq(['foo', 'bar'])
  view.columns.each do |column|
    expect(page).to have_content column
  end
end
