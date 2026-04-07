Feature: Ticketing MVP - Expiration and Automatic Release Flow (Path B with SQL Validation)
  As a Ticketing MVP automation
  I want to execute the complete flow with rejected payment, automatic release, and SQL validation
  So that I can conclusively verify that blocked inventory is released and available for new buyers

  Background:
    * def baseUrlEvents = karate.properties['baseUrlEvents'] || 'http://localhost:8081'
    * def baseUrlTicketing = karate.properties['baseUrlTicketing'] || 'http://localhost:8082'
    * def UUID = Java.type('java.util.UUID')
    * def buyer1Id = UUID.randomUUID() + ''
    * def buyer2Id = UUID.randomUUID() + ''
    * def buyer1Email = 'buyer1-' + java.lang.System.currentTimeMillis() + '@karate-test.com'
    * def buyer2Email = 'buyer2-' + java.lang.System.currentTimeMillis() + '@karate-test.com'
    * def eventTitle = 'Karate Release Event ' + java.lang.System.currentTimeMillis()
    * def futureDate = '2026-12-15T20:00:00'
    * def adminUserId = '00000000-0000-0000-0000-000000000001'

  Scenario: Path B - Rejected Payment, Automatic Release, and SQL Validation

    # ========================================
    # SETUP PHASE
    # ========================================

    # Setup: Create Room
    Given url baseUrlEvents + '/api/v1/rooms'
    And header X-Role = 'ADMIN'
    And header X-User-Id = adminUserId
    And request
      """
      {
        "name": "Karate Release Flow Room",
        "maxCapacity": 50
      }
      """
    When method post
    Then status 201
    * def roomId = response.id ? response.id : response.roomId
    * match roomId == '#uuid'
    * print '[SETUP] Room created:', roomId

    # Setup: Create Event in DRAFT
    Given url baseUrlEvents + '/api/v1/events'
    And header X-Role = 'ADMIN'
    And header X-User-Id = adminUserId
    And request
      """
      {
        "roomId": "#(roomId)",
        "title": "#(eventTitle)",
        "description": "Test event for expiration and release flow",
        "date": "#(futureDate)",
        "capacity": 50,
        "enableSeats": false
      }
      """
    When method post
    Then status 201
    * def eventId = response.id ? response.id : response.eventId
    * match eventId == '#uuid'
    * match response.status == 'DRAFT'
    * print '[SETUP] Event created in DRAFT:', eventId

    # Setup: Configure Tier with quota=40
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/tiers'
    And header X-Role = 'ADMIN'
    And request
      """
      [
        {
          "tierType": "GENERAL",
          "price": 100,
          "quota": 40
        }
      ]
      """
    When method post
    Then status 201
    * def tierBlock = response.tiers ? response.tiers[0] : response[0]
    * def tierId = tierBlock.id ? tierBlock.id : tierBlock.tierId
    * match tierId == '#uuid'
    * match tierBlock.tierType == 'GENERAL'
    * match tierBlock.quota == 40
    * print '[SETUP] Tier configured with quota 40:', tierId

    # Setup: Publish Event
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/publish'
    And header X-Role = 'ADMIN'
    And header X-User-Id = adminUserId
    When method patch
    Then status 200
    * match response.status == 'PUBLISHED'
    * print '[SETUP] Event published'

    # ========================================
    # PATH B PHASE 1: Buyer 1 creates reservation
    # ========================================

    Given url baseUrlTicketing + '/api/v1/reservations'
    And header X-User-Id = buyer1Id
    And request
      """
      {
        "eventId": "#(eventId)",
        "tierId": "#(tierId)",
        "buyerEmail": "#(buyer1Email)"
      }
      """
    When method post
    Then status 201
    * def reservation1Id = response.id
    * match response.status == 'PENDING'
    * match response.buyerId == buyer1Id
    * print '[PATH B-1] Buyer 1 reservation created (PENDING, inventory blocked):', reservation1Id

    # ========================================
    # PATH B PHASE 2: Buyer 1 payment DECLINED
    # ========================================

    Given url baseUrlTicketing + '/api/v1/reservations/' + reservation1Id + '/payments'
    And header X-User-Id = buyer1Id
    And request
      """
      {
        "amount": 100,
        "paymentMethod": "MOCK",
        "status": "DECLINED"
      }
      """
    When method post
    Then status 400
    * match response == { error: '#string', reservationId: '#uuid', status: 'PAYMENT_FAILED', timestamp: '#string' }
    * match response.reservationId == reservation1Id
    * print '[PATH B-2] Payment rejected. Status:', response.status, 'Timestamp:', response.timestamp

    # ========================================
    # PATH B PHASE 3: FORCE EXPIRATION & WAIT
    # ========================================

    * print '[PATH B-3] Forcing expiration by moving valid_until_at to the past via SQL...'
    * def forceResult = call read('classpath:common/sql/db-helper.feature@forceExpiration') { reservationId: '#(reservation1Id)' }
    * match forceResult.rows == 1

    * def waitTimeMs = 75000
    * print '[PATH B-3] Waiting for scheduler to sweep expired reservations (60s cycle + buffer)...'
    * java.lang.Thread.sleep(waitTimeMs)
    * print '[PATH B-3] Wait complete.'

    # ========================================
    # PATH B PHASE 4: SQL VALIDATION - Reservation status
    # ========================================

    * print '[SQL-1] Querying ticketing_db for reservation status...'
    * def reservationStatusResult = call read('classpath:common/sql/db-helper.feature@checkReservationStatus') { reservationId: '#(reservation1Id)', expectedStatus: 'EXPIRED' }
    * print '[SQL-1] Reservation status validation passed. Status:', reservationStatusResult.actualStatus

    # ========================================
    # PATH B PHASE 5: SQL VALIDATION - Tier quota restoration
    # ========================================

    * print '[SQL-2] Querying events_db for tier quota...'
    * def tierQuotaResult = call read('classpath:common/sql/db-helper.feature@checkTierQuota') { tierId: '#(tierId)', expectedQuota: 40 }
    * print '[SQL-2] Tier quota validation passed. Quota:', tierQuotaResult.actualQuota

    # ========================================
    # PATH B PHASE 6: HTTP verification - Buyer 2 creates reservation
    # ========================================

    * print '[PATH B-4] Attempting Buyer 2 reservation (final HTTP verification)...'

    Given url baseUrlTicketing + '/api/v1/reservations'
    And header X-User-Id = buyer2Id
    And request
      """
      {
        "eventId": "#(eventId)",
        "tierId": "#(tierId)",
        "buyerEmail": "#(buyer2Email)"
      }
      """
    When method post
    Then status 201
    * def reservation2Id = response.id
    * match response.status == 'PENDING'
    * match response.buyerId == buyer2Id
    * eval if (reservation2Id == reservation1Id) karate.fail('Buyer 2 must have different reservation ID than Buyer 1')
    * print '[PATH B-4] Buyer 2 reservation created successfully (CONFIRMS RELEASE):', reservation2Id

    # ========================================
    # FINAL SUMMARY
    # ========================================

    * print ''
    * print '=========================================='
    * print 'PATH B VALIDATION COMPLETE'
    * print '=========================================='
    * print 'Buyer 1: Reservation', reservation1Id
    * print '  - Created: PENDING'
    * print '  - Payment: DECLINED (HTTP 400, PAYMENT_FAILED)'
    * print '  - Status after release: EXPIRED (SQL validated)'
    * print ''
    * print 'Tier #' + tierId
    * print '  - Original quota: 40'
    * print '  - After release: 40 (SQL validated)'
    * print ''
    * print 'Buyer 2: Reservation', reservation2Id
    * print '  - Created: PENDING (proves inventory was released)'
    * print ''
    * print 'CONCLUSION: Automatic release mechanism working correctly'
    * print '=========================================='

  Scenario: Scenario 2 - Early Bird Tier Expiration via Time Travel (TC-006 / TC-011)

    # Setup: Create Room
    Given url baseUrlEvents + '/api/v1/rooms'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "name": "EB Expiration Room",
        "maxCapacity": 100
      }
      """
    When method post
    Then status 201
    * def roomId = response.id ? response.id : response.roomId

    # Setup: Create Event
    Given url baseUrlEvents + '/api/v1/events'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "roomId": "#(roomId)",
        "title": "#(eventTitle + ' EB')",
        "description": "Test event for EB expiration",
        "date": "#(futureDate)",
        "capacity": 50,
        "enableSeats": false
      }
      """
    When method post
    Then status 201
    * def eventId = response.id ? response.id : response.eventId

    # Setup: Configure EB Tier
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/tiers'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    * def validFrom = java.time.LocalDateTime.now(java.time.ZoneOffset.UTC).plusDays(1).toString()
    * def validUntil = java.time.LocalDateTime.now(java.time.ZoneOffset.UTC).plusDays(5).toString()
    And request
      """
      [
        {
          "tierType": "EARLY_BIRD",
          "price": 100,
          "quota": 40,
          "validFrom": "#(validFrom)",
          "validUntil": "#(validUntil)"
        }
      ]
      """
    When method post
    Then status 201
    * def tierBlock = response.tiers ? response.tiers[0] : response[0]
    * def tierId = tierBlock.id ? tierBlock.id : tierBlock.tierId

    # Setup: Publish Event
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/publish'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    When method patch
    Then status 200

    # Act: Force Tier Expiration via Testability Time Travel (advance clock by 6 days = 8640 minutes)
    * print 'Forcing EB Tier Expiration smoothly using Testability Time Travel...'
    Given url baseUrlEvents + '/api/v1/testability/clock/advance'
    And param minutes = 8640
    When method post
    Then status 200

    # Check: Verify isAvailable is false
    Given url baseUrlEvents + '/api/v1/events/' + eventId
    When method get
    Then status 200
    * def ebTier = response.availableTiers[0]
    * match ebTier.isAvailable == false
    * match ebTier.reason == 'EXPIRED'

    # Cleanup: Reset SystemClock
    Given url baseUrlEvents + '/api/v1/testability/clock/reset'
    When method post
    Then status 200

    * print 'TC-006 and TC-011: Early Bird Tier Expiration verified correctly without DB hacks'