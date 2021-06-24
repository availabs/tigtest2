# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :demographic_fact do
    # I'm not convinced this wouldn't be easier to load from a CSV instead of using 
    # factories, since we have to sort of jump through hoops to make factory_girl
    # use existing objects if they're available.
    # association :view, factory: :view, strategy: :find_or_create, name: 'View 1'
    # association :area, factory: :taz1625, strategy: :find_or_create, name: 'taz1625'
    view
    area
    year 2015
    # association :statistic, factory: :statistic, strategy: :find_or_create, name: 'Statistic 1'
    statistic
    value 1
  end
end
