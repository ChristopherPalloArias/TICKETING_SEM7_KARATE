@ignore
Feature: Generic CRUD Template API Testing
  As an automation framework
  I want to demonstrate a clean CRUD lifecycle test
  So that future tests can use this as a robust starting point

  Background: Configure API basics
    * url baseUrl
    * def resourcePath = '/posts' // Generic resource
    * header Accept = 'application/json'
    # * def token = call read('classpath:common/auth/get-token.feature')
    # * header Authorization = 'Bearer ' + token.accessToken

  Scenario: CREATE - Verify successful creation of a new resource
    Given path resourcePath
    * def requestPayload = read('classpath:common/payloads/request-template.json')
    And request requestPayload
    When method POST
    Then status 201
    And match response == read('classpath:common/schemas/response-template.json')
    # Capture the ID for subsequent steps if needed
    * def createdId = response.id

  Scenario: READ - Verify retrieval of an existing resource
    # Assume ID 1 exists for template purposes
    Given path resourcePath, 1
    When method GET
    Then status 200
    And match response.id == 1

  Scenario: UPDATE - Verify modification of a resource
    Given path resourcePath, 1
    And request { title: 'updated title', body: 'updated body', userId: 1 }
    When method PUT
    Then status 200
    And match response.title == 'updated title'

  Scenario: DELETE - Verify removal of a resource
    Given path resourcePath, 1
    When method DELETE
    Then status 200
    # or 204 depending on the API design
