package runners;

import com.intuit.karate.junit5.Karate;
import org.junit.jupiter.api.DisplayName;

@DisplayName("Tier Validation Negative and Early Bird")
public class TierValidationNegativeAndEarlyBirdTest {
    
    @Karate.Test
    Karate testTierValidationNegative() {
        return Karate.run("classpath:api/tier-validation-negative-and-earlybird/tier-validation-negative-and-earlybird.feature");
    }
}
