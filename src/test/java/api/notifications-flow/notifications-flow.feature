Feature: Ticketing MVP - Notifications Flow
  As a Ticketing MVP automation
  I want to validate that notifications are sent after key events
  So that I can verify the notification system is working correctly

  # Runtime: Notifications service is at port 8083 (ms-notifications)
  # Endpoint: GET /api/v1/notifications/buyer/{buyerId}
  # Response: { content: [...], page, size, totalElements, totalPages }
  # Notification types: PAYMENT_SUCCESS, PAYMENT_FAILED, RESERVATION_EXPIRED

  Background:
    * def baseUrlEvents = karate.properties['baseUrlEvents'] || 'http://localhost:8081'
    * def baseUrlTicketing = karate.properties['baseUrlTicketing'] || 'http://localhost:8082'
    * def baseUrlNotifications = karate.properties['baseUrlNotifications'] || 'http://localhost:8083'
    * def UUID = Java.type('java.util.UUID')
    * def futureDate = '2026-12-15T20:00:00'


  Scenario: Scenario 1 - Notification After Approved Purchase

    * def tag = UUID.randomUUID() + ''
    * def buyerId = UUID.randomUUID() + ''
    * def buyerEmail = 'buyer-s1-' + tag + '@karate-test.com'
    * def eventTitle = 'Notif S1 ' + tag

    # Setup: Create Room
    Given url baseUrlEvents + '/api/v1/rooms'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request { name: 'Notifications Room S1', maxCapacity: 100 }
    When method post
    Then status 201
    * def roomId = response.id

    # Setup: Create Draft Event
    Given url baseUrlEvents + '/api/v1/events'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "roomId": "#(roomId)",
        "title": "#(eventTitle)",
        "description": "Test event for approved purchase notification",
        "date": "#(futureDate)",
        "capacity": 50,
        "enableSeats": false
      }
      """
    When method post
    Then status 201
    * def eventId = response.id

    # Setup: Configure Tier
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/tiers'
    And header X-Role = 'ADMIN'
    And request
      """
      [{ "tierType": "GENERAL", "price": 100, "quota": 40 }]
      """
    When method post
    Then status 201
    * def tierId = response.tiers[0].id

    # Setup: Publish Event
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/publish'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    When method patch
    Then status 200

    # Create Reservation
    Given url baseUrlTicketing + '/api/v1/reservations'
    And header X-User-Id = buyerId
    And request
      """
      { "eventId": "#(eventId)", "tierId": "#(tierId)", "buyerEmail": "#(buyerEmail)" }
      """
    When method post
    Then status 201
    * def reservationId = response.id

    # Approved Payment
    Given url baseUrlTicketing + '/api/v1/reservations/' + reservationId + '/payments'
    And header X-User-Id = buyerId
    And request { amount: 100, paymentMethod: 'MOCK', status: 'APPROVED' }
    When method post
    Then status 200
    * match response.status == 'CONFIRMED'
    * print 'Payment approved - checking notification for buyer:', buyerId

    # Short wait for async notification processing
    * java.lang.Thread.sleep(5000)

    # Validate Notification via GET /api/v1/notifications/buyer/{buyerId}
    # Runtime: notifications service at 8083 returns paginated response
    Given url baseUrlNotifications + '/api/v1/notifications/buyer/' + buyerId
    And header X-User-Id = buyerId
    When method get
    Then status 200
    * print 'Notification response totalElements:', response.totalElements
    * assert response.totalElements >= 1
    * def notifications = response.content
    # Find PAYMENT_SUCCESS notification using Karate JsonPath expression
    * def paymentSuccessNotifs = $notifications[?(@.type == 'PAYMENT_SUCCESS')]
    * assert paymentSuccessNotifs.length > 0
    * def notif = paymentSuccessNotifs[0]
    * match notif.type == 'PAYMENT_SUCCESS'
    * match notif.status == 'PROCESSED'
    * match notif.buyerId == buyerId
    * print 'Scenario 1 PASS: PAYMENT_SUCCESS notification found for buyer:', buyerId


  Scenario: Scenario 2 - Notification After Rejected Payment

    * def tag = UUID.randomUUID() + ''
    * def buyerId = UUID.randomUUID() + ''
    * def buyerEmail = 'buyer-s2-' + tag + '@karate-test.com'
    * def eventTitle = 'Notif S2 ' + tag

    # Setup: Create Room
    Given url baseUrlEvents + '/api/v1/rooms'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request { name: 'Notifications Room S2', maxCapacity: 100 }
    When method post
    Then status 201
    * def roomId = response.id

    # Setup: Create Draft Event
    Given url baseUrlEvents + '/api/v1/events'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "roomId": "#(roomId)",
        "title": "#(eventTitle)",
        "description": "Test event for rejected payment notification",
        "date": "#(futureDate)",
        "capacity": 50,
        "enableSeats": false
      }
      """
    When method post
    Then status 201
    * def eventId = response.id

    # Setup: Configure Tier
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/tiers'
    And header X-Role = 'ADMIN'
    And request
      """
      [{ "tierType": "GENERAL", "price": 100, "quota": 40 }]
      """
    When method post
    Then status 201
    * def tierId = response.tiers[0].id

    # Setup: Publish Event
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/publish'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    When method patch
    Then status 200

    # Create Reservation
    Given url baseUrlTicketing + '/api/v1/reservations'
    And header X-User-Id = buyerId
    And request
      """
      { "eventId": "#(eventId)", "tierId": "#(tierId)", "buyerEmail": "#(buyerEmail)" }
      """
    When method post
    Then status 201
    * def reservationId = response.id

    # Declined Payment (runtime contract: HTTP 400, status=PAYMENT_FAILED)
    Given url baseUrlTicketing + '/api/v1/reservations/' + reservationId + '/payments'
    And header X-User-Id = buyerId
    And request { amount: 100, paymentMethod: 'MOCK', status: 'DECLINED' }
    When method post
    Then status 400
    * match response.status == 'PAYMENT_FAILED'
    * print 'Payment rejected - checking PAYMENT_FAILED notification for buyer:', buyerId

    # Short wait for async notification processing
    * java.lang.Thread.sleep(5000)

    # Validate Notification via GET /api/v1/notifications/buyer/{buyerId}
    Given url baseUrlNotifications + '/api/v1/notifications/buyer/' + buyerId
    And header X-User-Id = buyerId
    When method get
    Then status 200
    * print 'Notification response totalElements:', response.totalElements
    * assert response.totalElements >= 1
    * def notifications = response.content
    # Find PAYMENT_FAILED notification using Karate JsonPath expression
    * def paymentFailedNotifs = $notifications[?(@.type == 'PAYMENT_FAILED')]
    * assert paymentFailedNotifs.length > 0
    * def notif = paymentFailedNotifs[0]
    * match notif.type == 'PAYMENT_FAILED'
    * match notif.status == 'PROCESSED'
    * match notif.buyerId == buyerId
    * print 'Scenario 2 PASS: PAYMENT_FAILED notification found for buyer:', buyerId


  Scenario: Scenario 3 - Validate Notification Endpoint Availability and Contract

    # This scenario verifies the notification endpoint contract without creating new events
    # It uses a pre-existing notification from a previous test run

    Given url baseUrlNotifications + '/api/v1/notifications/buyer/00000000-0000-0000-0000-000000000999'
    And header X-User-Id = '00000000-0000-0000-0000-000000000999'
    When method get
    Then status 200
    # Runtime: paginated response even when empty
    * match response.content == '#array'
    * match response.totalElements == '#number'
    * match response.page == '#number'
    * match response.size == '#number'
    * print 'Scenario 3 PASS: Notification endpoint available and returns correct paginated contract'
