package runners;

import com.intuit.karate.junit5.Karate;
import org.junit.jupiter.api.DisplayName;

@DisplayName("Reservation Advanced Lifecycle")
public class ReservationAdvancedLifecycleTest {
    
    @Karate.Test
    Karate testReservationAdvancedLifecycle() {
        return Karate.run("classpath:api/reservation-advanced-lifecycle/reservation-advanced-lifecycle.feature");
    }
}
