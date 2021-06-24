# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :view do
    name "View 1"
    description "View 1 description"
    source_id ""
    current_version ""
    data_starts_at ""
    data_model CountFact
    data_ends_at ""
    origin_url ""
    user_id ""
    rows_updated_at ""
    rows_updated_by_id ""
    topic_area ""
    download_count 0
    last_displayed_at ""
    view_count 0
    data_levels ["", ""]
    spatial_level 'taz'
    data_hierarchy [
      ['taz', 'county', ['subregion', 'region']]
    ]

    factory :view2 do
      data_hierarchy [
            ['taz', 'county', ['subregion', 'region']]
          ]
    end

    # Note this data_hierarchy is not currently used in the data
    factory :view3 do
      data_hierarchy [
            ['taz', 'county', 'subregion', 'region']
          ]
    end
  end
end
