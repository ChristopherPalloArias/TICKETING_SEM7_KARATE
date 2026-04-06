package runners;

import com.intuit.karate.junit5.Karate;

class TicketVisibilityAndAccessControlTest {
  @Karate.Test
  Karate testTicketVisibility() {
    return Karate.run("classpath:api/ticket-visibility-and-access-control/ticket-visibility-and-access-control.feature")
        .relativeTo(getClass());
  }
}
