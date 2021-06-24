# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :source do
    name "MyString"
    description "MyText"
    current_version 1
    data_starts_at "2013-11-05 16:26:27"
    data_ends_at "2013-11-05 16:26:27"
    origin_url "MyString"
    user_id 1
    rows_updated_at "2013-11-05 16:26:27"
    rows_updated_by_id 1
    topic_area "MyString"
    source_type "MyString"
  end
end
