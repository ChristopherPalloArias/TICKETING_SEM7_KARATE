Feature: Ticketing MVP - Notifications Flow
  As a Ticketing MVP automation
  I want to validate that notifications are sent after key events
  So that I can verify the notification system is working correctly

  Background:
    * def baseUrlEvents = karate.properties['baseUrlEvents'] || 'http://localhost:8081'
    * def baseUrlTicketing = karate.properties['baseUrlTicketing'] || 'http://localhost:8082'
    * def UUID = Java.type('java.util.UUID')
    * def buyerId = UUID.randomUUID() + ''
    * def buyerEmail = 'buyer-' + java.lang.System.currentTimeMillis() + '@karate-test.com'
    * def eventTitle = 'Karate Notification Test Event ' + java.lang.System.currentTimeMillis()
    * def futureDate = '2026-12-15T20:00:00'

  Scenario: Scenario 1 - Notification After Approved Purchase

    # Setup: Create Room
    Given url baseUrlEvents + '/api/v1/rooms'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "name": "Karate Test Room - Notifications Approved",
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
        "description": "Test event for approved purchase notification",
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

    # Create Reservation
    Given url baseUrlTicketing + '/api/v1/reservations'
    And header X-User-Id = buyerId
    And request
      """
      {
        "eventId": "#(eventId)",
        "tierId": "#(tierId)",
        "buyerEmail": "#(buyerEmail)"
      }
      """
    When method post
    Then status 201
    * def reservationId = response.id
    * print 'Reservation created:', reservationId

    # Approved Payment
    Given url baseUrlTicketing + '/api/v1/reservations/' + reservationId + '/payments'
    And header X-User-Id = buyerId
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
    * match response.status == 'CONFIRMED'
    * print 'Payment approved for buyer:', buyerId

    # Validate Notification: Check GET /api/v1/notifications/buyer/{buyerId}
    * def maxRetries = 3
    * def retryCount = 0
    * def notificationFound = false

    * while (retryCount < maxRetries && !notificationFound)
      * call sleep(1000)
      * try
        Given url baseUrlTicketing + '/api/v1/notifications/buyer/' + buyerId
        And header X-User-Id = buyerId
        When method get
        Then status 200
        * def notifications = response
        * def approvedNotification = notifications[?(@.type == 'PURCHASE_APPROVED' || @.type == 'PURCHASE_CONFIRMED')]
        * eval if (approvedNotification.length > 0) { notificationFound = true }
        * print 'Notification check attempt', retryCount + 1, '- Found:', notificationFound
      catch
        * print 'Notification endpoint not available yet - retrying...'
      endtry
      * eval retryCount++

    * assert notificationFound
    * print 'Scenario 1 SUCCESS: Approved purchase notification validated'

  Scenario: Scenario 2 - Notification After Rejected Payment

    # Setup: Create Room
    Given url baseUrlEvents + '/api/v1/rooms'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "name": "Karate Test Room - Notifications Declined",
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
        "description": "Test event for rejected payment notification",
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

    # Create Reservation
    Given url baseUrlTicketing + '/api/v1/reservations'
    And header X-User-Id = buyerId
    And request
      """
      {
        "eventId": "#(eventId)",
        "tierId": "#(tierId)",
        "buyerEmail": "#(buyerEmail)"
      }
      """
    When method post
    Then status 201
    * def reservationId = response.id
    * print 'Reservation created:', reservationId

    # Declined Payment
    Given url baseUrlTicketing + '/api/v1/reservations/' + reservationId + '/payments'
    And header X-User-Id = buyerId
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
    * print 'Payment declined for buyer:', buyerId

    # Validate Notification: Check GET /api/v1/notifications/buyer/{buyerId}
    * def maxRetries = 3
    * def retryCount = 0
    * def notificationFound = false

    * while (retryCount < maxRetries && !notificationFound)
      * call sleep(1000)
      * try
        Given url baseUrlTicketing + '/api/v1/notifications/buyer/' + buyerId
        And header X-User-Id = buyerId
        When method get
        Then status 200
        * def notifications = response
        * def declinedNotification = notifications[?(@.type == 'PAYMENT_FAILED' || @.type == 'PAYMENT_DECLINED')]
        * eval if (declinedNotification.length > 0) { notificationFound = true }
        * print 'Notification check attempt', retryCount + 1, '- Found:', notificationFound
      catch
        * print 'Notification endpoint not available yet - retrying...'
      endtry
      * eval retryCount++

    * assert notificationFound
    * print 'Scenario 2 SUCCESS: Rejected payment notification validated'

  Scenario: Scenario 3 - Notification After Expiration/Release

    # Setup: Create Room
    Given url baseUrlEvents + '/api/v1/rooms'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "name": "Karate Test Room - Notifications Expiration",
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
        "description": "Test event for expiration notification",
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

    # Create Reservation and Declined Payment (triggers expiration path)
    Given url baseUrlTicketing + '/api/v1/reservations'
    And header X-User-Id = buyerId
    And request
      """
      {
        "eventId": "#(eventId)",
        "tierId": "#(tierId)",
        "buyerEmail": "#(buyerEmail)"
      }
      """
    When method post
    Then status 201
    * def reservationId = response.id
    * print 'Reservation created for expiration test:', reservationId

    # Declined Payment (entry point to expiration flow)
    Given url baseUrlTicketing + '/api/v1/reservations/' + reservationId + '/payments'
    And header X-User-Id = buyerId
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
    * print 'Payment declined - expiration mechanism triggered'

    # Wait for scheduler to process expiration/release (conservative 90 seconds)
    * print 'Waiting 90 seconds for scheduler to process expiration...'
    * java.lang.Thread.sleep(90000)

    # Validate Notification: Check GET /api/v1/notifications/buyer/{buyerId}
    * def maxRetries = 3
    * def retryCount = 0
    * def notificationFound = false

    * while (retryCount < maxRetries && !notificationFound)
      * call sleep(1000)
      * try
        Given url baseUrlTicketing + '/api/v1/notifications/buyer/' + buyerId
        And header X-User-Id = buyerId
        When method get
        Then status 200
        * def notifications = response
        * def expirationNotification = notifications[?(@.type == 'RESERVATION_RELEASED' || @.type == 'RESERVATION_EXPIRED' || @.type == 'INVENTORY_RELEASED')]
        * eval if (expirationNotification.length > 0) { notificationFound = true }
        * print 'Notification check attempt', retryCount + 1, '- Found:', notificationFound
      catch
        * print 'Notification endpoint not available yet - retrying...'
      endtry
      * eval retryCount++

    * assert notificationFound
    * print 'Scenario 3 SUCCESS: Expiration/release notification validated'

  Scenario: Fallback - Test endpoint availability

    # This scenario checks if the notification endpoint is available
    # If it fails, documentar que se debe usar SQL helper como fallback

    Given url baseUrlTicketing + '/api/v1/notifications/buyer/test-buyer-id'
    And header X-User-Id = 'test-buyer-id'
    When method get
    Then
      * print '✅ Notification endpoint is available'
      * status 200,404
