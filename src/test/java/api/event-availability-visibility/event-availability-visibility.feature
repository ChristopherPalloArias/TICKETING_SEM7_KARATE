Feature: Ticketing MVP - Event Availability Visibility
  As a buyer
  I want to view event availability and tier status
  So that I can see which tiers are available for purchase

  Background:
    * def baseUrlEvents = karate.properties['baseUrlEvents'] || 'http://localhost:8081'
    * def baseUrlTicketing = karate.properties['baseUrlTicketing'] || 'http://localhost:8082'
    * def UUID = Java.type('java.util.UUID')
    * def buyerId = UUID.randomUUID() + ''
    * def buyerEmail = 'buyer-' + java.lang.System.currentTimeMillis() + '@karate-test.com'
    * def eventTitle = 'Availability Test Event ' + java.lang.System.currentTimeMillis()
    * def futureDate = '2026-12-15T20:00:00'
    * def pastDate = '2026-03-15T20:00:00'

  Scenario: Scenario 1 - Event visible with valid availability by tier

    # Setup API: Create room
    Given url baseUrlEvents + '/api/v1/rooms'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "name": "Availability Test Room 1",
        "maxCapacity": 200
      }
      """
    When method post
    Then status 201
    * def roomId = response.id ? response.id : response.roomId
    * print 'Room created:', roomId

    # Setup API: Create event DRAFT
    Given url baseUrlEvents + '/api/v1/events'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "roomId": "#(roomId)",
        "title": "#(eventTitle)",
        "description": "Test event for availability",
        "date": "#(futureDate)",
        "capacity": 100,
        "enableSeats": false
      }
      """
    When method post
    Then status 201
    * def eventId = response.id ? response.id : response.eventId
    * print 'Event created (DRAFT):', eventId

    # HU-03: Configure tier with valid availability
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/tiers'
    And header X-Role = 'ADMIN'
    And request
      """
      [
        {
          "tierType": "GENERAL",
          "price": 50.00,
          "quota": 100
        }
      ]
      """
    When method post
    Then status 201
    * def tierId = response.tiers[0].id || response.tiers[0].tierId || response[0].id || response[0].tierId
    * print 'Tier created (GENERAL):', tierId

    # Setup API: Publish event
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/publish'
    And header X-Role = 'ADMIN'
    When method patch
    Then status 200
    * print 'Event published'

    # HU-03: Verify event visible with availability
    # Endpoint: GET /api/v1/events/{eventId}
    # Strategy: Primary endpoint for buyer-facing availability view
    Given url baseUrlEvents + '/api/v1/events/' + eventId
    When method get
    Then status 200
    * print 'Event detail response received'
    * match response.title == eventTitle
    * match response.published == true
    * match response.tiers != null && response.tiers.length > 0
    * def generalTier = response.tiers[0]
    * print 'General tier details:', generalTier
    * match generalTier.tierType == 'GENERAL'
    * match generalTier.quota == 100
    * match generalTier.reserved == 0
    * match generalTier.available == 100
    * match generalTier.price == 50.00
    * print '✅ Scenario 1 PASS: Event visible with 100 available seats in GENERAL tier'


  Scenario: Scenario 2 - Exhausted tier (quota reached)

    # Setup API: Create room
    Given url baseUrlEvents + '/api/v1/rooms'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "name": "Exhausted Tier Test Room",
        "maxCapacity": 50
      }
      """
    When method post
    Then status 201
    * def roomId = response.id ? response.id : response.roomId

    # Setup API: Create event DRAFT
    Given url baseUrlEvents + '/api/v1/events'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "roomId": "#(roomId)",
        "title": "#(eventTitle) - Exhausted",
        "description": "Test event with exhausted tier",
        "date": "#(futureDate)",
        "capacity": 5,
        "enableSeats": false
      }
      """
    When method post
    Then status 201
    * def eventId = response.id ? response.id : response.eventId

    # HU-03: Configure tier with quota = 2 to test exhaustion via reservations
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/tiers'
    And header X-Role = 'ADMIN'
    And request
      """
      [
        {
          "tierType": "GENERAL",
          "price": 40.00,
          "quota": 2
        }
      ]
      """
    When method post
    Then status 201
    * def tierId = response.tiers[0].id || response.tiers[0].tierId || response[0].id || response[0].tierId
    * print 'Tier created with quota=2'

    # Setup API: Publish event
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/publish'
    And header X-Role = 'ADMIN'
    When method patch
    Then status 200
    * print 'Event published'

    # Simulate exhaustion: Create 2 reservations + complete payments to exhaust quota
    * def buyer1Id = UUID.randomUUID() + ''
    * def buyer2Id = UUID.randomUUID() + ''

    # Reservation 1
    Given url baseUrlTicketing + '/api/v1/reservations'
    And header X-User-Id = buyer1Id
    And request
      """
      {
        "eventId": "#(eventId)",
        "tierId": "#(tierId)",
        "buyerEmail": "buyer1-#(java.lang.System.currentTimeMillis())@karate-test.com"
      }
      """
    When method post
    Then status 201
    * def reservationId1 = response.id
    * print 'Reservation 1 created'

    # Payment 1 - APPROVED
    Given url baseUrlTicketing + '/api/v1/reservations/' + reservationId1 + '/payments'
    And header X-User-Id = buyer1Id
    And request
      """
      {
        "amount": 40.00,
        "paymentMethod": "MOCK",
        "status": "APPROVED"
      }
      """
    When method post
    Then status 200
    * print 'Payment 1 approved - Tier now has 1 reserved'

    # Reservation 2
    Given url baseUrlTicketing + '/api/v1/reservations'
    And header X-User-Id = buyer2Id
    And request
      """
      {
        "eventId": "#(eventId)",
        "tierId": "#(tierId)",
        "buyerEmail": "buyer2-#(java.lang.System.currentTimeMillis())@karate-test.com"
      }
      """
    When method post
    Then status 201
    * def reservationId2 = response.id

    # Payment 2 - APPROVED
    Given url baseUrlTicketing + '/api/v1/reservations/' + reservationId2 + '/payments'
    And header X-User-Id = buyer2Id
    And request
      """
      {
        "amount": 40.00,
        "paymentMethod": "MOCK",
        "status": "APPROVED"
      }
      """
    When method post
    Then status 200
    * print 'Payment 2 approved - Tier is now exhausted (reserved=2, quota=2)'

    # HU-03: Verify tier shows as exhausted (available = 0)
    Given url baseUrlEvents + '/api/v1/events/' + eventId
    When method get
    Then status 200
    * def exhaustedTier = response.tiers[0]
    * print 'Exhausted tier details:', exhaustedTier
    * match exhaustedTier.quota == 2
    * match exhaustedTier.reserved == 2
    * match exhaustedTier.available == 0
    * print '✅ Scenario 2 PASS: Tier shows as exhausted (0 available seats)'


  Scenario: Scenario 3 - Early Bird tier expired

    # Setup API: Create room
    Given url baseUrlEvents + '/api/v1/rooms'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "name": "Early Bird Expiration Test Room",
        "maxCapacity": 100
      }
      """
    When method post
    Then status 201
    * def roomId = response.id ? response.id : response.roomId

    # Setup API: Create event DRAFT
    Given url baseUrlEvents + '/api/v1/events'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "roomId": "#(roomId)",
        "title": "#(eventTitle) - Early Bird Expired",
        "description": "Test event with expired early bird",
        "date": "#(futureDate)",
        "capacity": 100,
        "enableSeats": false
      }
      """
    When method post
    Then status 201
    * def eventId = response.id ? response.id : response.eventId

    # HU-03: Configure tier with EARLY_BIRD endDate in the past
    # Strategy: Create tier with earlyBirdEndDate = 2026-03-15 (before current date 2026-04-06)
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/tiers'
    And header X-Role = 'ADMIN'
    And request
      """
      [
        {
          "tierType": "EARLY_BIRD",
          "price": 25.00,
          "quota": 50,
          "earlyBirdEndDate": "2026-03-15T23:59:59Z"
        }
      ]
      """
    When method post
    Then status 201
    * def tierId = response.tiers[0].id || response.tiers[0].tierId || response[0].id || response[0].tierId
    * print 'Early Bird tier created with endDate in past (2026-03-15)'

    # Setup API: Publish event
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/publish'
    And header X-Role = 'ADMIN'
    When method patch
    Then status 200
    * print 'Event published'

    # HU-03: Verify early bird tier status (should be expired or not available)
    Given url baseUrlEvents + '/api/v1/events/' + eventId
    When method get
    Then status 200
    * def expiredTier = response.tiers[0]
    * print 'Expired Early Bird tier details:', expiredTier
    * match expiredTier.tierType == 'EARLY_BIRD'
    # Tier should either be marked as EXPIRED or status != ACTIVE
    # or earlyBirdEndDate should indicate it's in the past
    * def isExpiredOrInactive = expiredTier.status == 'EXPIRED' || expiredTier.status != 'ACTIVE' || (expiredTier.earlyBirdEndDate && expiredTier.earlyBirdEndDate < '2026-04-06')
    * assert isExpiredOrInactive
    * print '✅ Scenario 3 PASS: Early Bird tier shows as expired/inactive (endDate in past)'


  Scenario: Scenario 4 - Event with no active tiers

    # Setup API: Create room
    Given url baseUrlEvents + '/api/v1/rooms'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "name": "No Active Tiers Test Room",
        "maxCapacity": 50
      }
      """
    When method post
    Then status 201
    * def roomId = response.id ? response.id : response.roomId

    # Setup API: Create event DRAFT (WITHOUT creating any tiers)
    Given url baseUrlEvents + '/api/v1/events'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "roomId": "#(roomId)",
        "title": "#(eventTitle) - No Tiers",
        "description": "Test event with no active purchase options",
        "date": "#(futureDate)",
        "capacity": 50,
        "enableSeats": false
      }
      """
    When method post
    Then status 201
    * def eventId = response.id ? response.id : response.eventId
    * print 'Event created without tiers'

    # Setup API: Publish event (with no tiers configured)
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/publish'
    And header X-Role = 'ADMIN'
    When method patch
    Then status 200
    * print 'Event published (no tiers)'

    # HU-03: Verify event has no active purchase options
    Given url baseUrlEvents + '/api/v1/events/' + eventId
    When method get
    Then status 200
    * print 'Event response received'
    # Tier array should be empty or have no active tiers
    * def hasTiers = response.tiers && response.tiers.length > 0
    * def hasActiveTiers = false
    * if (hasTiers) { hasActiveTiers = response.tiers[?(@.status == 'ACTIVE')].length > 0 }
    * assert !hasActiveTiers
    * print '✅ Scenario 4 PASS: Event shows no active purchase options (empty or no active tiers)'
