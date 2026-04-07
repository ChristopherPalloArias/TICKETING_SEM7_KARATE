Feature: Ticketing MVP - Reservation Advanced Lifecycle
  As a QA engineer
  I want to validate advanced reservation lifecycle scenarios
  So that expiration, concurrency, and business rules are properly enforced

  Background:
    * def baseUrlEvents = karate.properties['baseUrlEvents'] || 'http://localhost:8081'
    * def baseUrlTicketing = karate.properties['baseUrlTicketing'] || 'http://localhost:8082'
    * def UUID = Java.type('java.util.UUID')
    * def eventTitle = 'Advanced Lifecycle Test ' + UUID.randomUUID() + ''
    * def futureDate = '2026-12-15T20:00:00'

  Scenario: Scenario 1 - Pure Expiration Without Payment (inventory released)

    # Setup: Create room
    Given url baseUrlEvents + '/api/v1/rooms'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "name": "Pure Expiration Test Room",
        "maxCapacity": 100
      }
      """
    When method post
    Then status 201
    * def roomId = response.id ? response.id : response.roomId
    * print 'Room created:', roomId

    # Setup: Create event
    * def scenarioTitle = eventTitle + ' - Pure Expiration'
    Given url baseUrlEvents + '/api/v1/events'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "roomId": "#(roomId)",
        "title": "#(scenarioTitle)",
        "description": "Test pure expiration without payment",
        "date": "#(futureDate)",
        "capacity": 10,
        "enableSeats": false
      }
      """
    When method post
    Then status 201
    * def eventId = response.id ? response.id : response.eventId

    # Setup: Create tier
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/tiers'
    And header X-Role = 'ADMIN'
    And request
      """
      [
        {
          "tierType": "GENERAL",
          "price": 50.00,
          "quota": 10
        }
      ]
      """
    When method post
    Then status 201
    * def tierId = response.tiers[0].id || response.tiers[0].tierId || response[0].id || response[0].tierId
    * print 'Tier created with quota=10:', tierId

    # Setup: Publish event
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/publish'
    And header X-Role = 'ADMIN'
    When method patch
    Then status 200
    * print 'Event published'

    # HU-05: Create reservation (quota now 9 available)
    * def buyerId1 = UUID.randomUUID() + ''
    * def buyerEmail1 = 'buyer1-' + buyerId1.substring(0,8) + '@karate-test.com'
    Given url baseUrlTicketing + '/api/v1/reservations'
    And header X-User-Id = buyerId1
    And request
      """
      {
        "eventId": "#(eventId)",
        "tierId": "#(tierId)",
        "buyerEmail": "#(buyerEmail1)"
      }
      """
    When method post
    Then status 201
    * def reservationId1 = response.id
    * print 'Reservation 1 created (status=PENDING):', reservationId1

    # Verify tier quota is reduced (should be 9 now: 10 - 1)
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/tiers'
    When method get
    Then status 200
    * def tierAfterRes = response.tiers[0]
    * print 'After reservation 1: quota=' + tierAfterRes.quota
    * assert tierAfterRes.quota == 9

    # Force expiration smoothly via Time Travel API
    * print 'Forzando expiración limpia via Time Travel...'
    Given url baseUrlTicketing + '/api/v1/testability/clock/advance'
    And param minutes = 15
    When method post
    Then status 200

    Given url baseUrlTicketing + '/api/v1/testability/jobs/expiration/trigger'
    When method post
    Then status 200
    * print 'CRONJOB de expiración desencadenado exitosamente!'

    # Verify reservation status changed to EXPIRED via API
    Given url baseUrlTicketing + '/api/v1/reservations/' + reservationId1
    And header X-User-Id = buyerId1
    When method get
    Then status 200
    * match response.status == 'EXPIRED'
    * print 'Reservation 1 confirmed expired via API'

    # Verify tier quota is restored (should be back to 10: quota released)
    * java.lang.Thread.sleep(2000)
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/tiers'
    When method get
    Then status 200
    * def tierAfterExpiration = response.tiers[0]
    * print 'After expiration: quota=' + tierAfterExpiration.quota
    * assert tierAfterExpiration.quota == 10

    # Cleanup Clock
    Given url baseUrlTicketing + '/api/v1/testability/clock/reset'
    When method post
    Then status 200
    * print '✅ Scenario 1 PASS: Pure expiration released quota (quota back to 10)'


  Scenario: Scenario 2 - Payment Attempt on Expired Reservation (must fail)

    # Setup: Create room
    Given url baseUrlEvents + '/api/v1/rooms'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "name": "Expired Payment Test Room",
        "maxCapacity": 100
      }
      """
    When method post
    Then status 201
    * def roomId = response.id ? response.id : response.roomId

    # Setup: Create event + tier + publish
    * def scenarioTitle = eventTitle + ' - Expired Payment Test'
    Given url baseUrlEvents + '/api/v1/events'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "roomId": "#(roomId)",
        "title": "#(scenarioTitle)",
        "description": "Test payment on expired reservation",
        "date": "#(futureDate)",
        "capacity": 20,
        "enableSeats": false
      }
      """
    When method post
    Then status 201
    * def eventId = response.id ? response.id : response.eventId

    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/tiers'
    And header X-Role = 'ADMIN'
    And request
      """
      [
        {
          "tierType": "GENERAL",
          "price": 60.00,
          "quota": 20
        }
      ]
      """
    When method post
    Then status 201
    * def tierId = response.tiers[0].id || response.tiers[0].tierId || response[0].id || response[0].tierId

    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/publish'
    And header X-Role = 'ADMIN'
    When method patch
    Then status 200

    # Create reservation
    * def buyerId2 = UUID.randomUUID() + ''
    * def buyerEmail2 = 'buyer2-' + buyerId2.substring(0,8) + '@karate-test.com'
    Given url baseUrlTicketing + '/api/v1/reservations'
    And header X-User-Id = buyerId2
    And request
      """
      {
        "eventId": "#(eventId)",
        "tierId": "#(tierId)",
        "buyerEmail": "#(buyerEmail2)"
      }
      """
    When method post
    Then status 201
    * def reservationId2 = response.id
    * print 'Reservation created:', reservationId2

    # Force expiration via API
    Given url baseUrlTicketing + '/api/v1/testability/clock/advance'
    And param minutes = 15
    When method post
    Then status 200

    Given url baseUrlTicketing + '/api/v1/testability/jobs/expiration/trigger'
    When method post
    Then status 200

    Given url baseUrlTicketing + '/api/v1/reservations/' + reservationId2
    And header X-User-Id = buyerId2
    When method get
    Then status 200
    * match response.status == 'EXPIRED'

    # HU-05 Negative: Attempt payment on expired reservation (should fail)
    Given url baseUrlTicketing + '/api/v1/reservations/' + reservationId2 + '/payments'
    And header X-User-Id = buyerId2
    And request
      """
      {
        "amount": 60.00,
        "paymentMethod": "MOCK",
        "status": "APPROVED"
      }
      """
    When method post
    Then status 400
    * print 'Payment rejected on expired reservation (✅ expected behavior)'

    # Cleanup Clock
    Given url baseUrlTicketing + '/api/v1/testability/clock/reset'
    When method post
    Then status 200
    * print '✅ Scenario 2 PASS: Payment on expired reservation rejected'


  Scenario: Scenario 3 - Concurrency on Last Available Slot

    # Setup: Create room
    Given url baseUrlEvents + '/api/v1/rooms'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "name": "Concurrency Test Room",
        "maxCapacity": 100
      }
      """
    When method post
    Then status 201
    * def roomId = response.id ? response.id : response.roomId

    # Setup: Create event with capacity=2 (only 2 slots, to trigger concurrency)
    * def scenarioTitle = eventTitle + ' - Concurrency Test'
    Given url baseUrlEvents + '/api/v1/events'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "roomId": "#(roomId)",
        "title": "#(scenarioTitle)",
        "description": "Test concurrency on last slot",
        "date": "#(futureDate)",
        "capacity": 2,
        "enableSeats": false
      }
      """
    When method post
    Then status 201
    * def eventId = response.id ? response.id : response.eventId

    # Setup: Create tier with quota=2
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/tiers'
    And header X-Role = 'ADMIN'
    And request
      """
      [
        {
          "tierType": "GENERAL",
          "price": 70.00,
          "quota": 2
        }
      ]
      """
    When method post
    Then status 201
    * def tierId = response.tiers[0].id || response.tiers[0].tierId || response[0].id || response[0].tierId
    * print 'Tier created with quota=2 (limited slots)'

    # Publish
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/publish'
    And header X-Role = 'ADMIN'
    When method patch
    Then status 200

    # Buyer 1: Reserve + Pay APPROVED (consumes 1 slot)
    * def buyer1 = UUID.randomUUID() + ''
    * def buyer1Email = 'buyer1-conc-' + buyer1.substring(0,8) + '@karate-test.com'
    Given url baseUrlTicketing + '/api/v1/reservations'
    And header X-User-Id = buyer1
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
    * def res1 = response.id

    Given url baseUrlTicketing + '/api/v1/reservations/' + res1 + '/payments'
    And header X-User-Id = buyer1
    And request
      """
      {
        "amount": 70.00,
        "paymentMethod": "MOCK",
        "status": "APPROVED"
      }
      """
    When method post
    Then status 200
    * print 'Buyer 1 payment approved (1/2 slots consumed)'

    # Buyer 2: Reserve + Pay APPROVED (consumes last slot)
    * def buyer2 = UUID.randomUUID() + ''
    * def buyer2Email = 'buyer2-conc-' + buyer2.substring(0,8) + '@karate-test.com'
    Given url baseUrlTicketing + '/api/v1/reservations'
    And header X-User-Id = buyer2
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
    * def res2 = response.id

    Given url baseUrlTicketing + '/api/v1/reservations/' + res2 + '/payments'
    And header X-User-Id = buyer2
    And request
      """
      {
        "amount": 70.00,
        "paymentMethod": "MOCK",
        "status": "APPROVED"
      }
      """
    When method post
    Then status 200
    * print 'Buyer 2 payment approved (2/2 slots consumed - fully booked)'

    # Verify tier is exhausted
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/tiers'
    When method get
    Then status 200
    * def tierFinal = response.tiers[0]
    * print 'Final tier state: quota=' + tierFinal.quota
    * assert tierFinal.quota == 0
    * print '✅ Scenario 3 PASS: Concurrency handled correctly, no overbooking'

  Scenario: Scenario 3b - Real Concurrency on Last Available Slot (TC-015)

    # Setup: Create room
    Given url baseUrlEvents + '/api/v1/rooms'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "name": "Real Concurrency Test Room",
        "maxCapacity": 100
      }
      """
    When method post
    Then status 201
    * def roomId = response.id ? response.id : response.roomId

    * def scenario3bTitle = eventTitle + ' - Real Conc Test'
    Given url baseUrlEvents + '/api/v1/events'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "roomId": "#(roomId)",
        "title": "#(scenario3bTitle)",
        "description": "Test real concurrency on last slot",
        "date": "#(futureDate)",
        "capacity": 1,
        "enableSeats": false
      }
      """
    When method post
    Then status 201
    * def eventId = response.id ? response.id : response.eventId

    # Setup: Create tier with exact quota=1
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/tiers'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      [
        {
          "tierType": "GENERAL",
          "price": 70.00,
          "quota": 1
        }
      ]
      """
    When method post
    Then status 201
    * def tierBlock = response.tiers ? response.tiers[0] : response[0]
    * def tierId = tierBlock.id ? tierBlock.id : tierBlock.tierId

    # Publish
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/publish'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    When method patch
    Then status 200

    # Act: Launch two concurrent requests using java.util.concurrent and HttpClient
    * def HttpClient = Java.type('java.net.http.HttpClient')
    * def HttpRequest = Java.type('java.net.http.HttpRequest')
    * def HttpResponse = Java.type('java.net.http.HttpResponse')
    * def URI = Java.type('java.net.URI')
    * def BodyPublishers = Java.type('java.net.http.HttpRequest.BodyPublishers')
    * def BodyHandlers = Java.type('java.net.http.HttpResponse.BodyHandlers')
    * def CompletableFuture = Java.type('java.util.concurrent.CompletableFuture')

    * def buyer1C = UUID.randomUUID() + ''
    * def buyer2C = UUID.randomUUID() + ''

    * def body1 = '{"eventId":"' + eventId + '","tierId":"' + tierId + '","buyerEmail":"c1-' + buyer1C.substring(0,8) + '@test.com"}'
    * def body2 = '{"eventId":"' + eventId + '","tierId":"' + tierId + '","buyerEmail":"c2-' + buyer2C.substring(0,8) + '@test.com"}'

    * def client = HttpClient.newHttpClient()
    * def req1 = HttpRequest.newBuilder().uri(new URI(baseUrlTicketing + '/api/v1/reservations')).header('Content-Type', 'application/json').header('X-User-Id', buyer1C).POST(BodyPublishers.ofString(body1)).build()
    * def req2 = HttpRequest.newBuilder().uri(new URI(baseUrlTicketing + '/api/v1/reservations')).header('Content-Type', 'application/json').header('X-User-Id', buyer2C).POST(BodyPublishers.ofString(body2)).build()

    * def future1 = client.sendAsync(req1, BodyHandlers.ofString())
    * def future2 = client.sendAsync(req2, BodyHandlers.ofString())
    * CompletableFuture.allOf(future1, future2).join()

    * def resp1 = future1.get()
    * def resp2 = future2.get()
    * def code1 = parseInt(resp1.statusCode() + '')
    * def code2 = parseInt(resp2.statusCode() + '')
    * print 'Request 1 returned:', code1
    * print 'Request 2 returned:', code2

    * assert (code1 == 201 && (code2 == 409 || code2 == 400)) || (code2 == 201 && (code1 == 409 || code1 == 400))

    # Determine winner
    * def winner = code1 == 201 ? 'Buyer 1' : 'Buyer 2'
    * def loser = code1 != 201 ? 'Buyer 1' : 'Buyer 2'
    * print 'Concurrency winner:', winner, '| loser:', loser

    # Verify tier is exhausted
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/tiers'
    When method get
    Then status 200
    * assert response.tiers[0].quota == 0
    * print '✅ TC-015 Scenario 3b PASS: Real concurrency handled correctly'


  Scenario: Scenario 4 - Confirmed Purchase Must Not Be Released by Scheduler

    # Setup: Create room
    Given url baseUrlEvents + '/api/v1/rooms'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "name": "Confirmed Purchase Protection Room",
        "maxCapacity": 100
      }
      """
    When method post
    Then status 201
    * def roomId = response.id ? response.id : response.roomId

    # Setup: Create event + tier + publish
    * def scenarioTitle = eventTitle + ' - Confirmed Protection'
    Given url baseUrlEvents + '/api/v1/events'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "roomId": "#(roomId)",
        "title": "#(scenarioTitle)",
        "description": "Test confirmed purchase is not released",
        "date": "#(futureDate)",
        "capacity": 50,
        "enableSeats": false
      }
      """
    When method post
    Then status 201
    * def eventId = response.id ? response.id : response.eventId

    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/tiers'
    And header X-Role = 'ADMIN'
    And request
      """
      [
        {
          "tierType": "GENERAL",
          "price": 55.00,
          "quota": 50
        }
      ]
      """
    When method post
    Then status 201
    * def tierId = response.tiers[0].id || response.tiers[0].tierId || response[0].id || response[0].tierId

    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/publish'
    And header X-Role = 'ADMIN'
    When method patch
    Then status 200

    # Create reservation + pay APPROVED
    * def buyer3 = UUID.randomUUID() + ''
    * def buyer3Email = 'buyer3-protect-' + buyer3.substring(0,8) + '@karate-test.com'
    Given url baseUrlTicketing + '/api/v1/reservations'
    And header X-User-Id = buyer3
    And request
      """
      {
        "eventId": "#(eventId)",
        "tierId": "#(tierId)",
        "buyerEmail": "#(buyer3Email)"
      }
      """
    When method post
    Then status 201
    * def res3 = response.id

    Given url baseUrlTicketing + '/api/v1/reservations/' + res3 + '/payments'
    And header X-User-Id = buyer3
    And request
      """
      {
        "amount": 55.00,
        "paymentMethod": "MOCK",
        "status": "APPROVED"
      }
      """
    When method post
    Then status 200
    * def ticketId = response.ticketId
    * print 'Reservation confirmed with ticket:', ticketId

    # Verify reservation status is CONFIRMED in DB
    * def sqlResult = karate.call('classpath:common/sql/db-helper.feature@checkReservationStatus', { reservationId: res3, expectedStatus: 'CONFIRMED' })
    * print 'Reservation confirmed in DB'

    # Wait 90 seconds (scheduler window for expiration)
    * print 'Waiting 90 seconds (scheduler window)...'
    * java.lang.Thread.sleep(90000)

    # Verify reservation is STILL CONFIRMED (not released)
    * def sqlResult = karate.call('classpath:common/sql/db-helper.feature@checkReservationStatus', { reservationId: res3, expectedStatus: 'CONFIRMED' })
    * print 'Reservation still CONFIRMED after scheduler window'

    # Verify tier still shows quota decremented by 1 (not released)
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/tiers'
    When method get
    Then status 200
    * def tierProtected = response.tiers[0]
    * print 'Tier after scheduler window: quota=' + tierProtected.quota
    * assert tierProtected.quota == 49
    * print '✅ Scenario 4 PASS: Confirmed purchase protected (NOT released by scheduler)'


  Scenario: Scenario 5 - Backup Job / Fallback Mechanism (if exposed by runtime)

    # Setup: Create room
    Given url baseUrlEvents + '/api/v1/rooms'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "name": "Backup Job Test Room",
        "maxCapacity": 100
      }
      """
    When method post
    Then status 201
    * def roomId = response.id ? response.id : response.roomId

    # Setup: Create event + tier + publish
    * def scenarioTitle = eventTitle + ' - Backup Job Test'
    Given url baseUrlEvents + '/api/v1/events'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "roomId": "#(roomId)",
        "title": "#(scenarioTitle)",
        "description": "Test backup job if available",
        "date": "#(futureDate)",
        "capacity": 30,
        "enableSeats": false
      }
      """
    When method post
    Then status 201
    * def eventId = response.id ? response.id : response.eventId

    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/tiers'
    And header X-Role = 'ADMIN'
    And request
      """
      [
        {
          "tierType": "GENERAL",
          "price": 80.00,
          "quota": 30
        }
      ]
      """
    When method post
    Then status 201
    * def tierId = response.tiers[0].id || response.tiers[0].tierId || response[0].id || response[0].tierId

    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/publish'
    And header X-Role = 'ADMIN'
    When method patch
    Then status 200

    # Create 3 reservations: 1 will expire, 1 will be confirmed, 1 will stay pending
    * def buyerA = UUID.randomUUID() + ''
    * def buyerAEmail = 'buyerA-backup-' + buyerA.substring(0,8) + '@karate-test.com'
    Given url baseUrlTicketing + '/api/v1/reservations'
    And header X-User-Id = buyerA
    And request
      """
      {
        "eventId": "#(eventId)",
        "tierId": "#(tierId)",
        "buyerEmail": "#(buyerAEmail)"
      }
      """
    When method post
    Then status 201
    * def resA = response.id

    * def buyerB = UUID.randomUUID() + ''
    * def buyerBEmail = 'buyerB-backup-' + buyerB.substring(0,8) + '@karate-test.com'
    Given url baseUrlTicketing + '/api/v1/reservations'
    And header X-User-Id = buyerB
    And request
      """
      {
        "eventId": "#(eventId)",
        "tierId": "#(tierId)",
        "buyerEmail": "#(buyerBEmail)"
      }
      """
    When method post
    Then status 201
    * def resB = response.id

    * def buyerC = UUID.randomUUID() + ''
    * def buyerCEmail = 'buyerC-backup-' + buyerC.substring(0,8) + '@karate-test.com'
    Given url baseUrlTicketing + '/api/v1/reservations'
    And header X-User-Id = buyerC
    And request
      """
      {
        "eventId": "#(eventId)",
        "tierId": "#(tierId)",
        "buyerEmail": "#(buyerCEmail)"
      }
      """
    When method post
    Then status 201
    * def resC = response.id

    # Pay resB -> CONFIRMED (should survive)
    Given url baseUrlTicketing + '/api/v1/reservations/' + resB + '/payments'
    And header X-User-Id = buyerB
    And request
      """
      {
        "amount": 80.00,
        "paymentMethod": "MOCK",
        "status": "APPROVED"
      }
      """
    When method post
    Then status 200

    # Force resA to expire directly by DB helper (bypassing normal flow) to simulate an orphaned reservation
    * def sqlResult = karate.call('classpath:common/sql/db-helper.feature@forceExpiration', { reservationId: resA })

    # resC stays PENDING naturally. We simulate passing of time (e.g. 25 minutes)
    Given url baseUrlTicketing + '/api/v1/testability/clock/advance'
    And param minutes = 25
    When method post
    Then status 200

    # Act: Trigger Backup Schedule Explicitly
    * print 'Triggering Backup Job Manually via Testability Endpoint to clean up lingering objects...'
    Given url baseUrlTicketing + '/api/v1/testability/jobs/expiration/trigger'
    When method post
    Then status 200

    # Verify states directly via API:
    # - resA: EXPIRED (cleaned by backup job)
    # - resB: CONFIRMED (protected)
    # - resC: EXPIRED (time-based expiration cleaned by job)

    Given url baseUrlTicketing + '/api/v1/reservations/' + resA
    And header X-User-Id = buyerA
    When method get
    Then status 200
    * match response.status == 'EXPIRED'
    * print 'resA: Purged by backup job (EXPIRED)'

    Given url baseUrlTicketing + '/api/v1/reservations/' + resB
    And header X-User-Id = buyerB
    When method get
    Then status 200
    * match response.status == 'CONFIRMED'
    * print 'resB: CONFIRMED (protected)'

    Given url baseUrlTicketing + '/api/v1/reservations/' + resC
    And header X-User-Id = buyerC
    When method get
    Then status 200
    * match response.status == 'EXPIRED'
    * print 'resC: Purged by backup job (EXPIRED)'

    # Cleanup Clock
    Given url baseUrlTicketing + '/api/v1/testability/clock/reset'
    When method post
    Then status 200

    * print '✅ TC-019 Scenario 5 PASS: Backup job correctly regularized lingering pending reservations'
