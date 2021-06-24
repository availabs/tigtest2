# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :statistic do
    name "Statistic 1"
    scale 1
  end
  factory :statistic2, class: Statistic do
    name "Statistic 2"
    scale 1
  end
end
