FactoryGirl.define do
  factory :snapshot do
    user
    name "MyString"
    description "MyText"
    view
    app 1
    area_id 1
    filters {}
    table_settings {}
    map_settings {}
  end

end
