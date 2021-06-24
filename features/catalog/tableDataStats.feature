Feature: A User can display a table with data and descriptions

  Background: View d has table data
    Given I have a catalog with multiple sources and views
    And Actions exist
    And View 1 has table columns

    @javascript
    Scenario: Set up TestFact
        Given TestFact exists
	
    @javascript
    Scenario: User selects the Table Action with a schema and data
        Given View 1 has table data
        When I view table for View 1
        Then I should land on the show table page
        And I should see a table for View 1
        And I should see table columns for View 1
        And I should see table data for View 1

    @javascript
    Scenario: User selects a Table view with a description
      Given View 1 has description "A Description"
      And View 1 has table data
      When I view table for View 1
      Then I should land on the show table page
      And I should see a table for View 1
      And I should see table columns for View 1
      And I should see table data for View 1
      And I should see caption "A Description"

    @javascript
    Scenario: User selects a Table view with a Population Statistic
      Given View 1 has statistic "Population" with scale "3"
      And View 1 has table data
      When I view table for View 1
      Then I should land on the show table page
      And I should see a table for View 1
      And I should see table columns for View 1
      And I should see table data for View 1
      And I should see caption "Population (in 000s)"

    @javascript
    Scenario: User selects a Table view with an Employment Statistic
      Given View 1 has statistic "Employment" with scale "6"
      And View 1 has table data
      When I view table for View 1
      Then I should land on the show table page
      And I should see a table for View 1
      And I should see table columns for View 1
      And I should see table data for View 1
      And I should see caption "Employment (in 000000s)"
