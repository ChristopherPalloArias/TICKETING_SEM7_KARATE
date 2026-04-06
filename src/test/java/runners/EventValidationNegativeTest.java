package runners;

import com.intuit.karate.junit5.Karate;
import org.junit.jupiter.api.DisplayName;

@DisplayName("Event Validation Negative Paths")
public class EventValidationNegativeTest {
    
    @Karate.Test
    Karate testEventValidationNegative() {
        return Karate.run("classpath:api/event-validation-negative/event-validation-negative.feature");
    }
}
