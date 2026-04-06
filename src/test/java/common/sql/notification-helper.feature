Feature: SQL Helper - Notification Validation (Fallback)
  Background:
    * def dbNotificationsUrl = karate.properties['dbNotificationsUrl'] || 'jdbc:postgresql://localhost:5435/notifications_db'
    * def dbNotificationsUser = karate.properties['dbNotificationsUser'] || 'postgres'
    * def dbNotificationsPass = karate.properties['dbNotificationsPass'] || 'postgres'
    * def JClass = Java.type('java.lang.Class')
    * def DriverManager = Java.type('java.sql.DriverManager')
    * JClass.forName('org.postgresql.Driver')

  # Parameters: buyerId (UUID string), notificationType (string: PAYMENT_SUCCESS | PAYMENT_FAILED | RESERVATION_EXPIRED)
  # Returns: { found: boolean, type: string, motif: string, createdAt: string, passed: boolean }
  @checkNotificationByBuyerId
  Scenario: Check Notification by BuyerId and Type
    * def sql = 'SELECT type, motif, created_at FROM notification WHERE buyer_id = ?::uuid AND type = ? ORDER BY created_at DESC LIMIT 1'
    * def conn = DriverManager.getConnection(dbNotificationsUrl, dbNotificationsUser, dbNotificationsPass)
    * def pstmt = conn.prepareStatement(sql)
    * pstmt.setObject(1, buyerId)
    * pstmt.setString(2, notificationType)
    * def rs = pstmt.executeQuery()
    * def found = rs.next()
    * def notif = {}
    * eval if (found) { notif = { type: rs.getString('type'), motif: rs.getString('motif'), createdAt: rs.getString('created_at') } }
    * rs.close()
    * pstmt.close()
    * conn.close()
    * print 'SQL Notification check: buyerId=' + buyerId + ', type=' + notificationType + ', found=' + found
    * eval if (!found) karate.fail('Notification not found for buyerId: ' + buyerId + ', type: ' + notificationType)
    * def response = { found: found, type: notif.type, motif: notif.motif, createdAt: notif.createdAt, passed: true }

  # Parameters: buyerId (UUID string), minExpected (int)
  # Returns: { count: number, passed: boolean }
  @checkNotificationCount
  Scenario: Count Notifications by BuyerId
    * def sql = "SELECT COUNT(*) as notification_count FROM notification WHERE buyer_id = ?::uuid AND created_at > NOW() - INTERVAL '1 hour'"
    * def conn = DriverManager.getConnection(dbNotificationsUrl, dbNotificationsUser, dbNotificationsPass)
    * def pstmt = conn.prepareStatement(sql)
    * pstmt.setObject(1, buyerId)
    * def rs = pstmt.executeQuery()
    * def count = 0
    * eval if (rs.next()) { count = rs.getInt('notification_count') }
    * rs.close()
    * pstmt.close()
    * conn.close()
    * print 'SQL Notification count for buyerId=' + buyerId + ': ' + count + ' (min expected: ' + minExpected + ')'
    * eval if (count < minExpected) karate.fail('Expected at least ' + minExpected + ' notifications, found: ' + count)
    * def response = { count: count, minExpected: minExpected, passed: true }
