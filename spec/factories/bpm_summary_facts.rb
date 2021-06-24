# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :bpm_summary_fact, :class => 'BpmSummaryFacts' do
    view nil
    area nil
    year 1
    orig_dest "MyString"
    purpose "MyString"
    mode "MyString"
    count 1
  end
end
