# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :taz1623, class: Area do
    name             "taz1623"
    type             "taz"
    size             3.338655
    base_geometry_id 2592 # TODO
    fips_code        nil    
  end
  factory :taz1624, class: Area do
    name             "taz1624"
    type             "taz"
    size             0.631877
    base_geometry_id 2593 # TODO
    fips_code        nil
  end
  factory :taz1625, class: Area do
    name             "taz1625"
    type             "taz"
    size             2.989205
    base_geometry_id 2590 # TODO
    fips_code        nil
  end

  factory :long_island, class: Area do
    name             "long_island"
    type             "subregion"
    size             1196.77
    base_geometry_id 3623
    fips_code        nil
  end

  # Note this is used for :bergen_county below, also
  factory :nybpm_counties, class: Area do
    name             "nybpm_counties"
    type             "region"
    size             nil
    base_geometry_id nil
    fips_code        nil
  end

  factory :nymtc_planning_area, class: Area do
    name             "nymtc_planning_area"
    type             "region"
    size             nil
    base_geometry_id nil
    fips_code        nil
  end

  factory :area do
    name             "Nassau"
    type             "county"
    size             284.72
    base_geometry_id 19 # TODO
    fips_code        nil
    after(:create) do |area, e|
      ['taz1623', 'taz1624', 'taz1625'].each do |a|
        area.enclosed_areas << FactoryGirl.find_or_create(a.to_sym, name: a)
      end

      ['long_island', 'nybpm_counties', 'nymtc_planning_area'].each do |a|
        area.enclosing_areas << FactoryGirl.find_or_create(a.to_sym, name: a)
      end
    end
  end


  factory :taz2661, class: Area do
    name              "2661"
    type              "taz"
    size              3.126107
    base_geometry_id  2847
    fips_code         nil
  end

  factory :taz2662, class: Area do
    name              "2662"
    type              "taz"
    size              6.358476
    base_geometry_id  2740
    fips_code         nil
  end

  factory :taz2663, class: Area do
    name              "2663"
    type              "taz"
    size              2.891565
    base_geometry_id  2876
    fips_code         nil
  end

  factory :new_jersey, class: Area do
    name              "New Jersey"
    type              "subregion"
    size              4389.64
    base_geometry_id  3621
    fips_code         nil
  end

  factory :bergen_county, class: Area do
    name              "Bergen"
    type              "county"
    size              233.01
    base_geometry_id  4
    fips_code         nil
    after(:create) do |area, e|
      ['taz2661', 'taz2662', 'taz2663'].each do |a|
        area.enclosed_areas << FactoryGirl.find_or_create(a.to_sym, name: a)
      end

      # Note we use :nybpm_counties
      ['new_jersey', 'nybpm_counties'].each do |a|
        area.enclosing_areas << FactoryGirl.find_or_create(a.to_sym, name: a)
      end
    end
  end

end
