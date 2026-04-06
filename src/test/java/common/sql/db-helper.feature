Feature: Database Helper - SQL Queries for Validation
  Provides reusable database validation steps using JDBC

  Background:
    * def dbTicketingUrl = karate.properties['dbTicketingUrl'] || 'jdbc:postgresql://localhost:5434/ticketing_db'
    * def dbTicketingUser = karate.properties['dbTicketingUser'] || 'postgres'
    * def dbTicketingPass = karate.properties['dbTicketingPass'] || 'postgres'

    * def dbEventsUrl = karate.properties['dbEventsUrl'] || 'jdbc:postgresql://localhost:5433/events_db'
    * def dbEventsUser = karate.properties['dbEventsUser'] || 'postgres'
    * def dbEventsPass = karate.properties['dbEventsPass'] || 'postgres'

    * def JClass = Java.type('java.lang.Class')
    * def DriverManager = Java.type('java.sql.DriverManager')
    * JClass.forName('org.postgresql.Driver')

  @forceExpiration
  Scenario: Force Reservation Expiration (Time Travel)
    * def sql = "UPDATE reservation SET valid_until_at = NOW() AT TIME ZONE 'UTC' - INTERVAL '2 days' WHERE id = ?::uuid"
    * def conn = DriverManager.getConnection(dbTicketingUrl, dbTicketingUser, dbTicketingPass)
    * def pstmt = conn.prepareStatement(sql)
    * pstmt.setObject(1, reservationId)
    * def rows = pstmt.executeUpdate()
    * pstmt.close()
    * conn.close()
    * print 'SQL Result: Forced expiration for reservationId=' + reservationId + ', Rows updated=' + rows
    * eval if (rows != 1) karate.fail('Expected exactly 1 reservation row to be updated, but updated ' + rows)
    * def response = { rowsUpdated: rows, passed: true }

  @checkReservationStatus
  Scenario: Check Reservation Status in Ticketing DB
    * def sql = 'SELECT status, updated_at FROM reservation WHERE id = ?::uuid ORDER BY updated_at DESC LIMIT 1'
    * def conn = DriverManager.getConnection(dbTicketingUrl, dbTicketingUser, dbTicketingPass)
    * def pstmt = conn.prepareStatement(sql)
    * pstmt.setObject(1, reservationId)
    * def rs = pstmt.executeQuery()

    * def found = rs.next()
    * eval if (!found) karate.fail('Reservation not found in database for id=' + reservationId)

    * def actualStatus = rs.getString('status')
    * def updatedAt = rs.getString('updated_at')

    * rs.close()
    * pstmt.close()
    * conn.close()

    * print 'SQL Result: reservationId=' + reservationId + ', status=' + actualStatus + ', updated_at=' + updatedAt
    * eval if (actualStatus != expectedStatus) karate.fail('Expected status ' + expectedStatus + ' but found ' + actualStatus)

    * def response = { actualStatus: actualStatus, updatedAt: updatedAt, passed: true }

  @checkTierQuota
  Scenario: Check Tier Quota in Events DB
    * def sql = 'SELECT quota, updated_at FROM tier WHERE id = ?::uuid'
    * def conn = DriverManager.getConnection(dbEventsUrl, dbEventsUser, dbEventsPass)
    * def pstmt = conn.prepareStatement(sql)
    * pstmt.setObject(1, tierId)
    * def rs = pstmt.executeQuery()

    * def found = rs.next()
    * eval if (!found) karate.fail('Tier not found in database for id=' + tierId)

    * def actualQuota = rs.getInt('quota')
    * def updatedAt = rs.getString('updated_at')

    * rs.close()
    * pstmt.close()
    * conn.close()

    * print 'SQL Result: tierId=' + tierId + ', quota=' + actualQuota + ', updated_at=' + updatedAt
    * eval if (actualQuota != expectedQuota) karate.fail('Expected quota ' + expectedQuota + ' but found ' + actualQuota)

    * def response = { actualQuota: actualQuota, updatedAt: updatedAt, passed: true }