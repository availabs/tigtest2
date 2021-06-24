Feature: A User can display a table for a view
  In order to see a table of data for a view
  Any User will need to be able to select a view with a table and then select the Table action.

  @javascript
  Scenario: User selects the Table Action
    Given I have a catalog with multiple sources and views
      And Actions exist
      And View b has table columns
      And View b has table data
      And I have opened the Catalog
      And I open source Source A
      And I choose View b
     When I select action: Table 
     Then I should land on the show table page
      And I should see a table for View b

  @javascript
  Scenario: User selects the Table Action with a schema
    Given I have a catalog with multiple sources and views
      And Actions exist
      And I have opened the Catalog
      And View c has table columns
      And View c has table data
      And I open source Source B
      And I choose View c
     When I select action: Table 
     Then I should land on the show table page
      And I should see a table for View c
      And I should see table columns for View c

  @javascript
  Scenario: User selects the Table Action with a schema and but no data
    Given I have a catalog with multiple sources and views
      And Actions exist
      And View b has table columns
      And View b has table data
     When I view table for View b
     Then I should land on the show table page
      And I should see a table for View b
      And I should see table columns for View b
      And I see item No data

