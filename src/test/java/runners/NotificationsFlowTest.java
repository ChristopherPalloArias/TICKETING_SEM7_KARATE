package runners;

import com.intuit.karate.junit5.Karate;

class NotificationsFlowTest {
  @Karate.Test
  Karate testNotificationsFlow() {
    return Karate.run("classpath:api/notifications-flow/notifications-flow.feature")
        .relativeTo(getClass());
  }
}
