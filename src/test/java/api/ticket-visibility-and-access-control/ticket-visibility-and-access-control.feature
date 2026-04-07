Feature: Ticketing MVP - Ticket Visibility and Access Control
  As a Ticketing MVP automation
  I want to validate ticket visibility, consistency, and access control
  So that I can verify tickets are secure and data is correct

  Background:
    * def baseUrlEvents = karate.properties['baseUrlEvents'] || 'http://localhost:8081'
    * def baseUrlTicketing = karate.properties['baseUrlTicketing'] || 'http://localhost:8082'
    * def UUID = Java.type('java.util.UUID')
    * def buyerId1 = UUID.randomUUID() + ''
    * def buyerId2 = UUID.randomUUID() + ''
    * def buyerId3 = UUID.randomUUID() + ''
    * def buyerEmail1 = 'buyer1-' + UUID.randomUUID() + '@karate-test.com'
    * def buyerEmail2 = 'buyer2-' + UUID.randomUUID() + '@karate-test.com'
    * def buyerEmail3 = 'buyer3-' + UUID.randomUUID() + '@karate-test.com'
    * def eventTitle = 'Karate Ticket Test Event ' + UUID.randomUUID()
    * def futureDate = '2026-12-15T20:00:00'

  # Covers TC-023 y TC-024
  Scenario: Scenario 1 - Ticket Visible for Owner (Happy Path)

    # Setup: Create Room
    Given url baseUrlEvents + '/api/v1/rooms'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "name": "Karate Test Room - Ticket Visibility",
        "maxCapacity": 100
      }
      """
    When method post
    Then status 201
    * def roomId = response.id ? response.id : response.roomId
    * print 'Room created:', roomId

    # Setup: Create Draft Event
    Given url baseUrlEvents + '/api/v1/events'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "roomId": "#(roomId)",
        "title": "#(eventTitle)",
        "description": "Test event for ticket visibility",
        "date": "#(futureDate)",
        "capacity": 50,
        "enableSeats": false
      }
      """
    When method post
    Then status 201
    * def eventId = response.id ? response.id : response.eventId
    * print 'Event created in DRAFT:', eventId

    # Setup: Configure Tier
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
    * print 'Tier configured:', tierId

    # Setup: Publish Event
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/publish'
    And header X-Role = 'ADMIN'
    When method patch
    Then status 200
    * print 'Event published'

    # HU-07 Path: Create Reservation (Buyer 1)
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
    * def reservationId = response.id
    * print 'Reservation created:', reservationId

    # HU-07 Path: Approved Payment (triggers ticket generation)
    Given url baseUrlTicketing + '/api/v1/reservations/' + reservationId + '/payments'
    And header X-User-Id = buyerId1
    And request
      """
      {
        "amount": 100,
        "paymentMethod": "MOCK",
        "status": "APPROVED"
      }
      """
    When method post
    Then status 200
    * match response.reservationId == reservationId
    * match response.status == 'CONFIRMED'
    * def ticketId = response.ticketId
    * print 'Payment approved, ticket generated:', ticketId

    # HU-07: GET /api/v1/tickets/{ticketId} as owner (Buyer 1)
    Given url baseUrlTicketing + '/api/v1/tickets/' + ticketId
    And header X-User-Id = buyerId1
    When method get
    Then status 200
    * match response == { ticketId: '#uuid', eventId: '#uuid', eventTitle: '#string', eventDate: '#string', tier: '#string', pricePaid: '#number', status: '#string', buyerEmail: '#string', reservationId: '#uuid', purchasedAt: '#string' }
    * match response.ticketId == ticketId
    * match response.eventId == eventId
    * match response.eventTitle == eventTitle
    * match response.tier == 'GENERAL'
    * match response.pricePaid == 100
    * match response.buyerEmail == buyerEmail1
    * match response.reservationId == reservationId
    * print 'Ticket retrieved successfully for owner:', ticketId

  # Extra Técnico / Variación de TC-025 - Validación por rechazo inmediato
  Scenario: Scenario 2 - No Ticket on Declined Payment (Negative Path)

    # Setup: Create Room
    Given url baseUrlEvents + '/api/v1/rooms'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "name": "Karate Test Room - Declined Payment",
        "maxCapacity": 100
      }
      """
    When method post
    Then status 201
    * def roomId = response.id ? response.id : response.roomId
    * print 'Room created:', roomId

    # Setup: Create Draft Event
    Given url baseUrlEvents + '/api/v1/events'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "roomId": "#(roomId)",
        "title": "#(eventTitle)",
        "description": "Test event for declined payment",
        "date": "#(futureDate)",
        "capacity": 50,
        "enableSeats": false
      }
      """
    When method post
    Then status 201
    * def eventId = response.id ? response.id : response.eventId
    * print 'Event created in DRAFT:', eventId

    # Setup: Configure Tier
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
    * print 'Tier configured:', tierId

    # Setup: Publish Event
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/publish'
    And header X-Role = 'ADMIN'
    When method patch
    Then status 200
    * print 'Event published'

    # HU-08 Path: Create Reservation (Buyer 1)
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
    * def reservationId = response.id
    * print 'Reservation created:', reservationId

    # HU-08 Path: Declined Payment
    Given url baseUrlTicketing + '/api/v1/reservations/' + reservationId + '/payments'
    And header X-User-Id = buyerId1
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
    * match response.status == 'PAYMENT_FAILED'
    * def hasTicketId = response.ticketId != null && response.ticketId != ''
    * assert !hasTicketId
    * print 'Payment declined, no ticket generated (as expected)'

  # Covers TC-027
  Scenario: Scenario 3 - Access Control (Buyer B Cannot Access Buyer A Ticket)

    # Setup: Create Room
    Given url baseUrlEvents + '/api/v1/rooms'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "name": "Karate Test Room - Access Control",
        "maxCapacity": 100
      }
      """
    When method post
    Then status 201
    * def roomId = response.id ? response.id : response.roomId
    * print 'Room created:', roomId

    # Setup: Create Draft Event
    Given url baseUrlEvents + '/api/v1/events'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "roomId": "#(roomId)",
        "title": "#(eventTitle)",
        "description": "Test event for access control",
        "date": "#(futureDate)",
        "capacity": 50,
        "enableSeats": false
      }
      """
    When method post
    Then status 201
    * def eventId = response.id ? response.id : response.eventId
    * print 'Event created in DRAFT:', eventId

    # Setup: Configure Tier
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
    * print 'Tier configured:', tierId

    # Setup: Publish Event
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/publish'
    And header X-Role = 'ADMIN'
    When method patch
    Then status 200
    * print 'Event published'

    # HU-09 Path: Buyer 1 creates Reservation and purchases ticket
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
    * def reservationId = response.id
    * print 'Reservation created by Buyer 1:', reservationId

    # Buyer 1: Approved Payment
    Given url baseUrlTicketing + '/api/v1/reservations/' + reservationId + '/payments'
    And header X-User-Id = buyerId1
    And request
      """
      {
        "amount": 100,
        "paymentMethod": "MOCK",
        "status": "APPROVED"
      }
      """
    When method post
    Then status 200
    * def ticketId = response.ticketId
    * print 'Buyer 1 purchased ticket:', ticketId

    # HU-09 Path: Buyer 2 attempts to access Buyer 1's ticket
    Given url baseUrlTicketing + '/api/v1/tickets/' + ticketId
    And header X-User-Id = buyerId2
    When method get
    Then status 403
    * print 'Buyer 2 access denied (403) - ticket belongs to Buyer 1'

  # Covers TC-025 - Ausencia de ticket tras expirar
  Scenario: Scenario 4 - No ticket shown for buyer when reservation expires without payment

    # Setup: Create Room
    Given url baseUrlEvents + '/api/v1/rooms'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "name": "Karate Test Room - Expired Ticket Check",
        "maxCapacity": 100
      }
      """
    When method post
    Then status 201
    * def roomId = response.id ? response.id : response.roomId

    # Setup: Create Draft Event
    Given url baseUrlEvents + '/api/v1/events'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "roomId": "#(roomId)",
        "title": "#(eventTitle + ' Expiration')",
        "description": "Test no ticket generated when expired",
        "date": "#(futureDate)",
        "capacity": 50,
        "enableSeats": false
      }
      """
    When method post
    Then status 201
    * def eventId = response.id ? response.id : response.eventId

    # Setup: Configure Tier
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

    # Setup: Publish Event
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/publish'
    And header X-Role = 'ADMIN'
    When method patch
    Then status 200

    # Path B: Create Reservation for Buyer 3
    Given url baseUrlTicketing + '/api/v1/reservations'
    And header X-User-Id = buyerId3
    And request
      """
      {
        "eventId": "#(eventId)",
        "tierId": "#(tierId)",
        "buyerEmail": "#(buyerEmail3)"
      }
      """
    When method post
    Then status 201
    * def reservationId = response.id
    * print 'Reservation created for Buyer 3 (PENDING):', reservationId

    # Path B: Force expiration using SQL mechanism to avoid 10 min hard sleep
    * print 'Forcing expiration via DB timeout mechanism...'
    * def sqlResult = karate.call('classpath:common/sql/db-helper.feature@forceExpiration', { reservationId: reservationId })
    * print 'Waiting 65s for backend scheduler to clean up...'
    * java.lang.Thread.sleep(65000)

    # Path B: Check reservation is truly expired
    * def checkResult = karate.call('classpath:common/sql/db-helper.feature@checkReservationStatus', { reservationId: reservationId, expectedStatus: 'EXPIRED' })
    * print 'Reservation successfully expired in backend.'

    # Act: Buyer 3 fetches their tickets
    Given url baseUrlTicketing + '/api/v1/tickets'
    And param buyerId = buyerId3
    And header X-User-Id = buyerId3
    When method get
    Then status 200
    * print 'Tickets retrieved for Buyer 3:', response

    # Assertion: Buyer 3 should have NO tickets associated (empty content array)
    * match response.content == []
    * match response.totalElements == 0
    * print 'Verified: Buyer 3 has no tickets. TC-025 passed!'
