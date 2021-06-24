Feature: A User can display a table of demographic facts

  Background: Demographic fact data exists not view tagged
    Given I have a catalog with multiple sources and views
    And Actions exist
    And statistic "Population" with scale "3" exists
    And statistic "Employment" with scale "3" exists
    And area "Area 51" exists
    And area "Area 52" exists
    And these facts exist:
      | year | area | stat | value | view  |
      | 2020 |   51 | Pop  |     1 | view1 |
      | 2025 |   51 | Pop  |     2 | view1 |
      | 2020 |   52 | Pop  |    10 | view1 |
      | 2025 |   52 | Pop  |    11 | view1 |
      | 2020 |   51 | Emp  |     1 | view1 |
      | 2025 |   51 | Emp  |     2 | view1 |
      | 2020 |   52 | Emp  |    10 | view1 |
      | 2025 |   52 | Emp  |    11 | view1 |
      | 2020 |   51 | Pop  |     2 | view2 |
      | 2025 |   51 | Pop  |     4 | view2 |
      | 2020 |   52 | Pop  |    20 | view2 |
      | 2025 |   52 | Pop  |    22 | view2 |

      @javascript
      Scenario: User views Pop table for 2020
        Given "View1" with stat "Pop" for years "2020"
        When I view table for View1
        Then I should see columns "area,2020" for "View1"
        And I should see 2 data rows
        And I should see row "Area 51,1"
        And I should see row "Area 52,10"

      @javascript
      Scenario: User views Pop table for 2020, 2025
        Given "View1" with stat "Pop" for years "2020,2025"
        When I view table for View1
        Then I should see columns "area,2020,2025" for "View1"
        And I should see 2 data rows
        And I should see row "Area 51,1,2"
        And I should see row "Area 52,10,11"

      @javascript
      Scenario: User views Pop table for 2020, 2025 for View2
        Given "View2" with stat "Pop" for years "2020,2025"
        When I view table for View2
        Then I should see columns "area,2020,2025" for "View2"
        And I should see 2 data rows
        And I should see row "Area 51,2,4"
        And I should see row "Area 52,20,22"
