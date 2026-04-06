Feature: SQL Helpers for Reservation and Tier State Validation
  Provides reusable SQL validation steps for expiration/release flow

  Scenario: Check Reservation Status in Ticketing DB
    # Requires: reservationId, expectedStatus
    # Example: expectedStatus = 'EXPIRED', 'RELEASED', 'PENDING', 'CONFIRMED', 'PAYMENT_FAILED'
    Given def dbUrl = config.ticketingDb.url
    And def dbUser = config.ticketingDb.username
    And def dbPassword = config.ticketingDb.password
    And def dbDriver = config.ticketingDb.driverClassName
    
    * def DbUtils = Java.type('karate.db.DbUtils')
    * def connection = DbUtils.getConnection(dbDriver, dbUrl, dbUser, dbPassword)
    * def query = 'SELECT status, updated_at FROM reservations WHERE id = ?::uuid'
    * def result = DbUtils.execQuerySingle(connection, query, [reservationId])
    * connection.close()
    
    Then print 'Reservation status from DB:', result.status
    And eval if (result.status != expectedStatus) karate.fail('Expected status ' + expectedStatus + ' but got ' + result.status)

  Scenario: Check Tier Quota in Events DB
    # Requires: tierId, expectedQuota
    # Example: expectedQuota = 40 (should be restored after release)
    Given def dbUrl = config.eventsDb.url
    And def dbUser = config.eventsDb.username
    And def dbPassword = config.eventsDb.password
    And def dbDriver = config.eventsDb.driverClassName
    
    * def DbUtils = Java.type('karate.db.DbUtils')
    * def connection = DbUtils.getConnection(dbDriver, dbUrl, dbUser, dbPassword)
    * def query = 'SELECT quota, reserved FROM tiers WHERE id = ?::uuid'
    * def result = DbUtils.execQuerySingle(connection, query, [tierId])
    * connection.close()
    
    Then print 'Tier quota from DB:', result.quota, 'Reserved:', result.reserved
    And eval if (result.quota != expectedQuota) karate.fail('Expected quota ' + expectedQuota + ' but got ' + result.quota)
