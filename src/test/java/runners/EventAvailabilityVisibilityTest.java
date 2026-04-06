package runners;

import com.intuit.karate.junit5.Karate;
import org.junit.jupiter.api.DisplayName;

@DisplayName("Event Availability Visibility")
public class EventAvailabilityVisibilityTest {
    
    @Karate.Test
    Karate testEventAvail() {
        return Karate.run("classpath:api/event-availability-visibility/event-availability-visibility.feature");
    }
}
