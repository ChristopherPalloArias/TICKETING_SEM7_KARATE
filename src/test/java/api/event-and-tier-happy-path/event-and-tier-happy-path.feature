Feature: Ticketing MVP - Event and Tier Creation Happy Path
  As a Ticketing MVP automation
  I want to validate the happy path for creating events and tiers
  So that I can verify the basic configuration capabilities of the system

  Background:
    * def baseUrlEvents = karate.properties['baseUrlEvents'] || 'http://localhost:8081'
    * def UUID = Java.type('java.util.UUID')
    * def eventTitle1 = 'Karate Event 1 ' + UUID.randomUUID()
    * def eventTitle2 = 'Karate Event 2 ' + UUID.randomUUID()
    * def futureDate = '2026-12-15T20:00:00'

  # Covers TC-001
  Scenario: Scenario 1 - Create an event with valid data within max capacity (TC-001)
    # Setup: Create Room (maxCapacity=300)
    Given url baseUrlEvents + '/api/v1/rooms'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "name": "Sala Principal TC-001",
        "maxCapacity": 300
      }
      """
    When method post
    Then status 201
    * def roomId = response.id ? response.id : response.roomId

    # TC-001: Create event with capacity=250 (<= 300)
    Given url baseUrlEvents + '/api/v1/events'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "roomId": "#(roomId)",
        "title": "#(eventTitle1)",
        "description": "Event for TC-001",
        "date": "#(futureDate)",
        "capacity": 250,
        "enableSeats": false
      }
      """
    When method post
    Then status 201
    * match response.title == eventTitle1
    * match response.capacity == 250
    * match response.date contains '2026-12-15T20:00'
    * match response.roomId == roomId
    * print 'Event successfully persisted with valid capacity (250/300)'

  # Covers TC-005
  Scenario: Scenario 2 - Configure three tiers on an existing event (TC-005)
    # Setup: Create Room (maxCapacity=300)
    Given url baseUrlEvents + '/api/v1/rooms'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "name": "Sala Principal TC-005",
        "maxCapacity": 300
      }
      """
    When method post
    Then status 201
    * def roomId = response.id ? response.id : response.roomId

    # Setup: Create event with capacity=300
    Given url baseUrlEvents + '/api/v1/events'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "roomId": "#(roomId)",
        "title": "#(eventTitle2)",
        "description": "Event for TC-005",
        "date": "#(futureDate)",
        "capacity": 300,
        "enableSeats": false
      }
      """
    When method post
    Then status 201
    * def eventId = response.id ? response.id : response.eventId

    # TC-005: Create VIP, GENERAL, and EARLY_BIRD tiers (total 300)
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/tiers'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      [
        {
          "tierType": "VIP",
          "price": 45,
          "quota": 50
        },
        {
          "tierType": "GENERAL",
          "price": 25,
          "quota": 200
        },
        {
          "tierType": "EARLY_BIRD",
          "price": 18,
          "quota": 50
        }
      ]
      """
    When method post
    Then status 201
    * def tiers = response.tiers ? response.tiers : response
    * match tiers[0].tierType == 'VIP'
    * match tiers[0].price == 45
    * match tiers[0].quota == 50
    * match tiers[1].tierType == 'GENERAL'
    * match tiers[1].price == 25
    * match tiers[1].quota == 200
    * match tiers[2].tierType == 'EARLY_BIRD'
    * match tiers[2].price == 18
    * match tiers[2].quota == 50
    * print 'All three tiers correctly persisted.'
