Given /^TestFact exists$/ do
  Temping.create :testFact do
    with_columns do |t|
      t.string :foo
      t.integer :bar
    end
    attr_accessible :foo, :bar
    def self.pivot?
      false
    end
  end

  TestFact.create([ { foo: 'First', bar: 1 },
                    { foo: 'Second', bar: 2 }
                  ] )
end

Given /^(.*) has table columns$/ do |name|
  view = View.find_by(name: name)
  view.columns = ['foo', 'bar']
  view.save if view.changed?
end

# Given /^(.*) has table data$/ do |name|
#   view = View.find_by(name: name)
#   view.data_model = TestFact
#   view.save if view.changed?
# end

Given(/^(.*) has description "(.*?)"$/) do |name, description|
  View.find_by(name: name).update_attributes(description: description)
end

Given(/^(.*) has statistic "(.*?)" with scale "(.*?)"$/) do |view, name, scale|
  stat = Statistic.find_or_create_by(name: name)
  stat.update_attributes(scale: scale)
  View.find_by(name: view).update_attributes(statistic: stat)
end

Then(/^I should see table columns for (.*)$/) do |name|
  view = View.find_by(name: name)
  expect(view.columns).to eq(['foo', 'bar'])
  view.columns.each do |column|
    expect(page).to have_selector('th', text: column.titleize)
  end
end

Then(/^I should see table data for (.*)$/) do |name|
  view = View.find_by(name: name)
  expect(view.columns).to eq(['foo', 'bar'])
  expect(page).to have_selector('tr', count: view.data_model.count + 1) # for header
  view.data_model.all.each do |row|
    view.columns.each do |column|
      expect(page).to have_selector('td', text: row[column])
    end
  end
end

Then(/^I should see caption "(.*?)"$/) do |description|
  expect(page).to have_selector('h4', text: description)
end

# Demographic table steps

Given(/^statistic "(.*?)" with scale "(.*?)" exists$/) do |name, scale|
  stat = Statistic.find_or_create_by(name: name)
  stat.update_attributes(scale: scale)
end

Given(/^area "(.*?)" exists$/) do |name|
  area = Area.find_or_create_by(name: name)
  area.update_attributes(type: 'county')
end

Given(/^these facts exist:$/) do |facts_table|
  # table is a Cucumber::Ast::Table
  facts_table.hashes.each do |hash|
    view = View.find_or_create_by(name: hash[:view].titleize)
    area = Area.where("name LIKE :suffix", suffix: "%#{hash[:area]}").first!
    stat = Statistic.where("name LIKE :prefix", prefix: "#{hash[:stat]}%").first!
    fact = DemographicFact.where(view_id: view,
                                 year: hash[:year],
                                 area_id: area,
                                 statistic_id: stat).first_or_create
    fact.update_attributes(value: hash[:value])
  end
end

Given(/^"(.*?)" with stat "(.*?)" for years "(.*?)"$/) do |view, stat, years|
  view = View.find_or_create_by(name: view)
  stat = Statistic.where("name LIKE :prefix", prefix: stat).first
  columns = ['area']
  years.split(',').each {|year| columns << year}
  view.update_attributes(statistic: stat,
                         columns: columns,
                         data_model: DemographicFact,
                         data_levels: ["", ""])
end

Then(/^I should see columns "(.*?)" for "(.*?)"$/) do |column_list, view|
  view = View.find_by(name: view)
  columns = column_list.split(',')
  expect(view.columns).to eq(columns)
  columns.each do |column|
    expect(page).to have_selector('th', text: column.titleize)
  end
end

Then(/^I should see (\d+) data rows$/) do |count|
  expect(page).to have_selector('tr', count: count.to_i + 1) # for header
end

Then(/^I should see row "(.*?)"$/) do |row_list|
  row_list.split(',').each do |value|
    expect(page).to have_selector('td', text: value)
  end
end
