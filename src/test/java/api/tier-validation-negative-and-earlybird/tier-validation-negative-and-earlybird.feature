Feature: Ticketing MVP - Tier Validation Negative and Early Bird
  As a system admin
  I want validation errors when creating tiers with invalid config
  So that tier integrity is maintained

  Background:
    * def baseUrlEvents = karate.properties['baseUrlEvents'] || 'http://localhost:8081'
    * def UUID = Java.type('java.util.UUID')
    * def eventTitle = 'Tier Validation Test ' + java.lang.System.currentTimeMillis()
    * def futureDate = '2026-12-15T20:00:00'
    * def now = java.time.Instant.now().toString()
    * def pastDate = '2026-03-15T23:59:59Z'
    * def nearFutureDate = '2026-12-31T23:59:59Z'

  Scenario: Scenario 1 - Early Bird visible within window and expired outside window

    # Setup: Create room
    Given url baseUrlEvents + '/api/v1/rooms'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "name": "Early Bird Test Room",
        "maxCapacity": 100
      }
      """
    When method post
    Then status 201
    * def roomId = response.id ? response.id : response.roomId
    * print 'Room created:', roomId

    # Setup: Create event DRAFT
    Given url baseUrlEvents + '/api/v1/events'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "roomId": "#(roomId)",
        "title": "#(eventTitle) - Early Bird Test",
        "description": "Test event for Early Bird visibility",
        "date": "#(futureDate)",
        "capacity": 100,
        "enableSeats": false
      }
      """
    When method post
    Then status 201
    * def eventId = response.id ? response.id : response.eventId
    * print 'Event created (DRAFT):', eventId

    # HU-02 Negative: Create Early Bird tier with endDate in PAST (already expired)
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/tiers'
    And header X-Role = 'ADMIN'
    And request
      """
      [
        {
          "tierType": "EARLY_BIRD",
          "price": 25.00,
          "quota": 30,
          "earlyBirdEndDate": "2026-03-15T23:59:59Z"
        }
      ]
      """
    When method post
    Then status 201
    * def expiredEarlyBirdTierId = response.tiers[0].id || response.tiers[0].tierId || response[0].id || response[0].tierId
    * print 'Early Bird tier created with past endDate:', expiredEarlyBirdTierId

    # Publish event
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/publish'
    And header X-Role = 'ADMIN'
    When method patch
    Then status 200
    * print 'Event published'

    # HU-02 Validation: Retrieve event and verify expired Early Bird tier is NOT active/visible
    Given url baseUrlEvents + '/api/v1/events/' + eventId
    When method get
    Then status 200
    * def tiers = response.tiers
    * def expiredEarlyBird = tiers[?(@.tierType == 'EARLY_BIRD' && @.earlyBirdEndDate == '2026-03-15T23:59:59Z')]
    * def isExpiredOrInactive = tiers[?(@.tierType == 'EARLY_BIRD')][0].status != 'ACTIVE' || tiers[?(@.tierType == 'EARLY_BIRD')][0].status == 'EXPIRED'
    * print 'Early Bird tier status (outside window):', tiers[?(@.tierType == 'EARLY_BIRD')][0].status
    * assert isExpiredOrInactive || expiredEarlyBird.length == 0
    * print '✅ Scenario 1a PASS: Expired Early Bird not visible/active outside window'

    # HU-02 Alternative: Create another event with Early Bird window in the FUTURE
    # (This demonstrates Early Bird visible WITHIN window)
    Given url baseUrlEvents + '/api/v1/events'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "roomId": "#(roomId)",
        "title": "#(eventTitle) - Early Bird Future Window",
        "description": "Test event with future Early Bird window",
        "date": "#(futureDate)",
        "capacity": 80,
        "enableSeats": false
      }
      """
    When method post
    Then status 201
    * def eventId2 = response.id ? response.id : response.eventId
    * print 'Second test event created:', eventId2

    # Create Early Bird tier with endDate in FUTURE (still valid)
    Given url baseUrlEvents + '/api/v1/events/' + eventId2 + '/tiers'
    And header X-Role = 'ADMIN'
    And request
      """
      [
        {
          "tierType": "EARLY_BIRD",
          "price": 30.00,
          "quota": 40,
          "earlyBirdEndDate": "2026-12-31T23:59:59Z"
        }
      ]
      """
    When method post
    Then status 201
    * def activEarlyBirdTierId = response.tiers[0].id || response.tiers[0].tierId || response[0].id || response[0].tierId
    * print 'Early Bird tier created with future endDate:', activEarlyBirdTierId

    # Publish second event
    Given url baseUrlEvents + '/api/v1/events/' + eventId2 + '/publish'
    And header X-Role = 'ADMIN'
    When method patch
    Then status 200

    # Retrieve event and verify active Early Bird tier IS visible
    Given url baseUrlEvents + '/api/v1/events/' + eventId2
    When method get
    Then status 200
    * def tiers2 = response.tiers
    * def activeEarlyBird = tiers2[?(@.tierType == 'EARLY_BIRD' && @.earlyBirdEndDate == '2026-12-31T23:59:59Z')]
    * print 'Active Early Bird tier details:', activeEarlyBird[0]
    * match activeEarlyBird[0].status == 'ACTIVE'
    * print '✅ Scenario 1b PASS: Early Bird visible/active within window'


  Scenario: Scenario 2 - Invalid price rejected (0 or negative)

    # Setup: Create room
    Given url baseUrlEvents + '/api/v1/rooms'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "name": "Price Validation Test Room",
        "maxCapacity": 100
      }
      """
    When method post
    Then status 201
    * def roomId = response.id ? response.id : response.roomId

    # Setup: Create event DRAFT
    Given url baseUrlEvents + '/api/v1/events'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "roomId": "#(roomId)",
        "title": "#(eventTitle) - Price Validation",
        "description": "Test event for price validation",
        "date": "#(futureDate)",
        "capacity": 100,
        "enableSeats": false
      }
      """
    When method post
    Then status 201
    * def eventId = response.id ? response.id : response.eventId

    # HU-02 Negative: Attempt to create tier with price = 0 (invalid)
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/tiers'
    And header X-Role = 'ADMIN'
    And request
      """
      [
        {
          "tierType": "GENERAL",
          "price": 0,
          "quota": 50
        }
      ]
      """
    When method post
    Then status !201
    * print 'Request rejected - price=0 is invalid (✅ expected error)'

    # HU-02 Negative: Attempt to create tier with negative price
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/tiers'
    And header X-Role = 'ADMIN'
    And request
      """
      [
        {
          "tierType": "VIP",
          "price": -50.00,
          "quota": 20
        }
      ]
      """
    When method post
    Then status !201
    * print 'Request rejected - negative price is invalid (✅ expected error)'


  Scenario: Scenario 3 - Tier quota exceeds event capacity

    # Setup: Create room
    Given url baseUrlEvents + '/api/v1/rooms'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "name": "Quota Capacity Test Room",
        "maxCapacity": 200
      }
      """
    When method post
    Then status 201
    * def roomId = response.id ? response.id : response.roomId

    # Setup: Create event DRAFT with capacity = 100
    Given url baseUrlEvents + '/api/v1/events'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "roomId": "#(roomId)",
        "title": "#(eventTitle) - Quota Overflow",
        "description": "Test event for quota capacity validation",
        "date": "#(futureDate)",
        "capacity": 100,
        "enableSeats": false
      }
      """
    When method post
    Then status 201
    * def eventId = response.id ? response.id : response.eventId
    * print 'Event created with capacity=100'

    # HU-02 Negative: Attempt to create tier with quota=150 (exceeds event capacity=100)
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/tiers'
    And header X-Role = 'ADMIN'
    And request
      """
      [
        {
          "tierType": "GENERAL",
          "price": 75.00,
          "quota": 150
        }
      ]
      """
    When method post
    Then status !201
    * print 'Request rejected - tier quota exceeds event capacity (✅ expected error)'

    # Note: If backend supports validating multiple tiers in single request,
    # update this scenario to test total of multiple tiers > capacity.
    # For now, each tier is tested individually as a potential overflow.
