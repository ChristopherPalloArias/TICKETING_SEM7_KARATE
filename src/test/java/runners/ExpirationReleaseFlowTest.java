package runners;

import com.intuit.karate.junit5.Karate;

public class ExpirationReleaseFlowTest {
    
    @Karate.Test
    Karate testExpirationReleaseFlow() {
        return Karate.run("classpath:api/expiration-release-flow/expiration-release-flow.feature").relativeTo(getClass());
    }
}
