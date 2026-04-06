Feature: SQL Helper - Notification Validation (Fallback)
  Background:
    * def baseUrlTicketing = karate.properties['baseUrlTicketing'] || 'http://localhost:8082'

  Scenario: @checkNotificationByBuyerId
    # Parameters:
    # - buyerId: UUID del comprador
    # - notificationType: tipo de notificación a buscar (PURCHASE_APPROVED, PAYMENT_FAILED, RESERVATION_RELEASED, etc.)
    # - maxAgeSeconds: tiempo máximo en segundos desde creación
    #
    # Returns:
    # - {found: boolean, count: number, latestNotification: object, passed: boolean}

    * def sql = 'SELECT type, message, created_at FROM notifications WHERE buyer_id = $1 AND type = $2 AND created_at > NOW() - INTERVAL \'1 hour\' ORDER BY created_at DESC LIMIT 1'
    * def Class = Java.type('java.lang.Class')
    * def DriverManager = Java.type('java.sql.DriverManager')
    
    * Class.forName('org.postgresql.Driver')
    * def conn = DriverManager.getConnection('jdbc:postgresql://localhost:5432/notifications_db', 'postgres', 'postgres')
    * def pstmt = conn.prepareStatement(sql)
    * pstmt.setObject(1, buyerId)
    * pstmt.setString(2, notificationType)
    * def rs = pstmt.executeQuery()
    
    * def found = false
    * def latestNotification = {}
    * eval if (rs.next()) { found = true; latestNotification = { type: rs.getString('type'), message: rs.getString('message'), created_at: rs.getString('created_at') } }
    
    * rs.close()
    * pstmt.close()
    * conn.close()
    
    * def result = { found: found, notificationType: notificationType, latestNotification: latestNotification, passed: found }
    * eval if (!found) { karate.fail('Notification not found for buyerId: ' + buyerId + ', type: ' + notificationType) }

  Scenario: @checkNotificationCount
    # Parameters:
    # - buyerId: UUID del comprador
    # - minExpected: número mínimo de notificaciones esperadas
    #
    # Returns:
    # - {count: number, passed: boolean}

    * def sql = 'SELECT COUNT(*) as notification_count FROM notifications WHERE buyer_id = $1 AND created_at > NOW() - INTERVAL \'1 hour\''
    * def Class = Java.type('java.lang.Class')
    * def DriverManager = Java.type('java.sql.DriverManager')
    
    * Class.forName('org.postgresql.Driver')
    * def conn = DriverManager.getConnection('jdbc:postgresql://localhost:5432/notifications_db', 'postgres', 'postgres')
    * def pstmt = conn.prepareStatement(sql)
    * pstmt.setObject(1, buyerId)
    * def rs = pstmt.executeQuery()
    
    * def count = 0
    * eval if (rs.next()) { count = rs.getInt('notification_count') }
    
    * rs.close()
    * pstmt.close()
    * conn.close()
    
    * def result = { count: count, minExpected: minExpected, passed: count >= minExpected }
    * eval if (!result.passed) { karate.fail('Expected at least ' + minExpected + ' notifications, found: ' + count) }
