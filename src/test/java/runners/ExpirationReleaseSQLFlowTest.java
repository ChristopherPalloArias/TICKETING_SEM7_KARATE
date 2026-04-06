package runners;

import com.intuit.karate.junit5.Karate;

public class ExpirationReleaseSQLFlowTest {
    
    @Karate.Test
    Karate testExpirationReleaseSQLFlow() {
        return Karate.run("classpath:api/expiration-release-flow/expiration-release-flow-with-sql.feature").relativeTo(getClass());
    }
}
