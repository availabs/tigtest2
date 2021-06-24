# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :rtp_project do
    geography "MyText"
    plan_portion nil
    rtp_id_201 "MyString"
    description "MyText"
    sponsor nil
    ptype nil
    year 1
    estimated_cost 1.5
    county nil
  end
end
