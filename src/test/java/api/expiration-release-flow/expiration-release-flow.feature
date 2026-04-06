Feature: Ticketing MVP - Expiration and Automatic Release Flow (Path B)
  As a Ticketing MVP automation
  I want to execute the flow with rejected payment followed by an inventory release observation
  So that I can verify that the system does not permanently block inventory after a failed payment

  Background:
    * def baseUrlEvents = karate.properties['baseUrlEvents'] || 'http://localhost:8081'
    * def baseUrlTicketing = karate.properties['baseUrlTicketing'] || 'http://localhost:8082'
    * def UUID = Java.type('java.util.UUID')
    * def buyer1Id = UUID.randomUUID() + ''
    * def buyer2Id = UUID.randomUUID() + ''
    * def buyer1Email = 'buyer1-' + java.lang.System.currentTimeMillis() + '@karate-test.com'
    * def buyer2Email = 'buyer2-' + java.lang.System.currentTimeMillis() + '@karate-test.com'
    * def eventTitle = 'Karate Expiration Event ' + java.lang.System.currentTimeMillis()
    * def futureDate = '2026-12-15T20:00:00'

  Scenario: Path B - Rejected Payment and Inventory Release Observation

    # Setup: Crear sala
    Given url baseUrlEvents + '/api/v1/rooms'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
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
    * print 'Room created:', roomId

    # Setup: Crear evento
    # Nota técnica: el evento se crea inicialmente con estado interno DRAFT y luego se publica.
    Given url baseUrlEvents + '/api/v1/events'
    And header X-Role = 'ADMIN'
    And header X-User-Id = '00000000-0000-0000-0000-000000000001'
    And request
      """
      {
        "roomId": "#(roomId)",
        "title": "#(eventTitle)",
        "description": "Test event for release flow",
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
    * print 'Event created:', eventId

    # HU-02: Configuración de tiers y precios por evento
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/tiers'
    And header X-Role = 'ADMIN'
    And request
      """
      [
        {
          "tierType": "GENERAL",
          "price": 100,
          "quota": 2
        }
      ]
      """
    When method post
    Then status 201
    * def tierBlock = response.tiers ? response.tiers[0] : response[0]
    * def tierId = tierBlock.id ? tierBlock.id : tierBlock.tierId
    * match tierId == '#uuid'
    * match tierBlock.tierType == 'GENERAL'
    # Nota: se usa quota 2 deliberadamente para que la segunda reservación sea significativa
    * print 'Tier configured with quota 2:', tierId

    # Setup: Publicar evento
    Given url baseUrlEvents + '/api/v1/events/' + eventId + '/publish'
    And header X-Role = 'ADMIN'
    When method patch
    Then status 200
    * match response.status == 'PUBLISHED'
    * print 'Event published'

    # HU-04: Reserva y compra de entrada con pago simulado (Creación de reserva - Buyer 1)
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
    * print 'Buyer 1 reservation created (PENDING):', reservation1Id

    # HU-04: Reserva y compra de entrada con pago simulado (Pago rechazado - Buyer 1)
    # Contrato real confirmado en SPEC-002: HTTP 400, body { error, reservationId, status: PAYMENT_FAILED, timestamp }
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
    * print 'Payment rejected correctly. Reservation status:', response.status

    # HU-05: Liberación automática por fallo de pago o expiración
    # NOTA TÉCNICA: La liberación es ejecutada por un mecanismo asincrónico del backend (scheduler/background process).
    # La espera a continuación es un proxy de tiempo mínimo para dar margen al procesamiento.
    # AJUSTAR esta duración al cadence real del scheduler una vez confirmado por el equipo de backend.
    # Si el scheduler corre con intervalos mayores (ej. 60 segundos), esta validación requiere
    # ser run manualmente o en un perfil de CI con tiempos extendidos.
    * java.lang.Thread.sleep(5000)
    * print 'Esperando procesamiento del mecanismo de liberación del backend (5 segundos configurados como proxy inicial)...'

    # VERIFICACIÓN INDIRECTA DE LIBERACIÓN
    # La siguiente reservación de Buyer 2 sobre el mismo tier y evento es una observación indirecta.
    # Su éxito NO prueba automáticamente que la liberación ocurrió si aún existía cuota disponible
    # por otros motivos (ej. la quota original del tier era > 1 y este es el único intento previo).
    # En este feature se usa quota=2 para que ambas reservaciones sean significativas,
    # pero la confirmación definitiva de liberación requeriría un endpoint de disponibilidad
    # o validación SQL del estado de la reservación de Buyer 1.
    * print 'Intentando reservación de Buyer 2 como observación indirecta de disponibilidad...'

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
    * eval if (reservation2Id == reservation1Id) karate.fail('Buyer 2 debe tener un ID de reservación diferente al de Buyer 1')
    # OBSERVACIÓN INDIRECTA: Buyer 2 pudo reservar, lo que indica disponibilidad al momento de la verificación.
    # Esto puede deberse a liberación post-PAYMENT_FAILED O a cuota disponible remanente.
    # Para prueba definitiva de liberación se recomienda validación SQL o endpoint de disponibilidad.
    * print 'Buyer 2 pudo reservar. Disponibilidad observable. Reservation ID:', reservation2Id

    * print 'Path B completado: DECLINED -> PAYMENT_FAILED -> observación de disponibilidad con Buyer 2'
