Feature: Ticketing MVP - Rejected Payment Flow
  As a Ticketing MVP automation
  I want to execute the rejected payment path
  So that I can verify the system correctly rejects declined payments without confirming a purchase

  Background:
    * def baseUrlEvents = karate.properties['baseUrlEvents'] || 'http://localhost:8081'
    * def baseUrlTicketing = karate.properties['baseUrlTicketing'] || 'http://localhost:8082'
    * def UUID = Java.type('java.util.UUID')
    * def buyerId = UUID.randomUUID() + ''
    * def buyerEmail = 'buyer-' + java.lang.System.currentTimeMillis() + '@karate-test.com'
    * def eventTitle = 'Karate Rejected Payment Event ' + java.lang.System.currentTimeMillis()
    * def futureDate = '2026-12-15T20:00:00'

  Scenario: HU-04 - Rejected Payment Flow (DECLINED)

    # Setup API: Crear sala
    Given url baseUrlEvents + '/api/v1/rooms'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "name": "Karate Rejected Payment Room",
        "maxCapacity": 100
      }
      """
    When method post
    Then status 201
    * def roomId = response.id ? response.id : response.roomId
    * match roomId == '#uuid'

    # Setup API: Crear evento
    # Nota técnica: el evento se crea inicialmente con estado interno DRAFT y luego se publica.
    Given url baseUrlEvents + '/api/v1/events'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "roomId": "#(roomId)",
        "title": "#(eventTitle)",
        "description": "Test event for rejected payment flow",
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

    # HU-02: Configuración de tiers y precios por evento
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

    # Setup API: Publicar evento
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/publish'
    And header X-Role = 'ADMIN'
    When method patch
    Then status 200
    * match response.status == 'PUBLISHED'

    # HU-04: Reserva y compra de entrada con pago simulado (Creación de reserva)
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
    * match response == { id: '#uuid', eventId: '#uuid', tierId: '#uuid', buyerId: '#uuid', status: 'PENDING', createdAt: '#string', updatedAt: '#string', validUntilAt: '#string' }

    # HU-04: Reserva y compra de entrada con pago simulado (Pago rechazado)
    # Según GlobalExceptionHandler: PaymentFailedException → HTTP 400, body: { error, reservationId, status: "PAYMENT_FAILED", timestamp }
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
    * match response.reservationId == reservationId
    * match response == { error: '#string', reservationId: '#uuid', status: 'PAYMENT_FAILED', timestamp: '#string' }
    * print 'Payment correctly rejected. Reservation status:', response.status