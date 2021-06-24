FactoryGirl.define do
  factory :access_control do
    source
    view
    agency_id nil
    user_id nil
    role nil
    show true
    download true
    comment true
  end
end
