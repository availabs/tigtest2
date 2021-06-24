Feature: A User can view metadata
  In order to see the metadata for a source or view
  Any User will need to view the metadata for any given source or view
@javascript  
  Scenario: User views metadata for Source
    Given I have a catalog with multiple sources and views
    And I have opened the Catalog
    When I select Metadata for Source A
    Then I should be sent to Metadata for Source A
@javascript    
  Scenario: User views metadata for View
    Given I have a catalog with multiple sources and views
      And I have opened the Catalog
      And I open source Source A
     When I select Metadata for View a
     Then I should be sent to Metadata for View a
@javascript  
  Scenario: User sees origin url in metadata for Source
    Given I have a catalog with multiple sources and views
      And I have opened the Catalog
     When I select Metadata for Source A
     Then I should be sent to Metadata for Source A
      And I should see link to http://camsys.com
@javascript
   Scenario: User sees columns in metadata for View 
    Given I have a catalog with multiple sources and views
    And View b has table columns
    And I have opened the Catalog
    And I open source Source A
    When I view metadata for View b
    Then I should see columns for View b

