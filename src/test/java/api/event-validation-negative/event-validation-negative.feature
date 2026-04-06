Feature: Ticketing MVP - Event Validation Negative Paths
  As a system admin
  I want validation errors when creating events with invalid data
  So that data integrity is maintained

  Background:
    * def baseUrlEvents = karate.properties['baseUrlEvents'] || 'http://localhost:8081'
    * def UUID = Java.type('java.util.UUID')
    * def eventTitle = 'Negative Test Event ' + java.lang.System.currentTimeMillis()
    * def futureDate = '2026-12-15T20:00:00'

  Scenario: Scenario 1 - Capacity exceeds room maxCapacity

    # HU-01 Negative: Capacity > maxCapacity should be rejected
    # Setup: Create room with maxCapacity=50
    Given url baseUrlEvents + '/api/v1/rooms'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "name": "Small Room for Negative Test",
        "maxCapacity": 50
      }
      """
    When method post
    Then status 201
    * def roomId = response.id ? response.id : response.roomId
    * print 'Room created with maxCapacity=50:', roomId

    # HU-01 Negative: Attempt to create event with capacity=100 (exceeds maxCapacity=50)
    Given url baseUrlEvents + '/api/v1/events'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "roomId": "#(roomId)",
        "title": "#(eventTitle) - Capacity Overflow",
        "description": "Test event with capacity exceeding room max",
        "date": "#(futureDate)",
        "capacity": 100,
        "enableSeats": false
      }
      """
    When method post
    Then status !201
    * print 'Request rejected - capacity exceeds maxCapacity (✅ expected error)'
    # Runtime validation: IF response has error field, it will be captured in status code
    # We do NOT assume specific error message or structure


  Scenario: Scenario 2 - Missing required field: date

    # HU-01 Negative: Missing date should be rejected
    # Setup: Create room
    Given url baseUrlEvents + '/api/v1/rooms'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "name": "Room for Missing Date Test",
        "maxCapacity": 100
      }
      """
    When method post
    Then status 201
    * def roomId = response.id ? response.id : response.roomId
    * print 'Room created:', roomId

    # HU-01 Negative: Attempt to create event WITHOUT date
    Given url baseUrlEvents + '/api/v1/events'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "roomId": "#(roomId)",
        "title": "#(eventTitle) - No Date",
        "description": "Test event without date field",
        "capacity": 50,
        "enableSeats": false
      }
      """
    When method post
    Then status !201
    * print 'Request rejected - date field missing (✅ expected error)'
    # Note: If your backend requires validating the exact error message,
    # add assertions here after confirming structure with actual response


  Scenario: Scenario 3 - Missing multiple required fields (title + date)

    # HU-01 Negative: Missing title AND date should be rejected
    # Setup: Create room
    Given url baseUrlEvents + '/api/v1/rooms'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "name": "Room for Multiple Missing Fields Test",
        "maxCapacity": 150
      }
      """
    When method post
    Then status 201
    * def roomId = response.id ? response.id : response.roomId
    * print 'Room created:', roomId

    # HU-01 Negative: Attempt to create event WITHOUT title and WITHOUT date
    Given url baseUrlEvents + '/api/v1/events'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "roomId": "#(roomId)",
        "description": "Test event without title and date",
        "capacity": 75,
        "enableSeats": false
      }
      """
    When method post
    Then status !201
    * print 'Request rejected - multiple required fields missing (✅ expected error)'
    # Note: If your backend provides detailed validation errors per field,
    # update this scenario to validate response.errors or response.validationErrors
    # per the actual contract once confirmed
