package runners;

import com.intuit.karate.junit5.Karate;

public class PurchaseApprovedFlowTest {
    
    @Karate.Test
    Karate testPurchaseApprovedFlow() {
        return Karate.run("classpath:api/purchase-approved-flow/purchase-approved-flow.feature").relativeTo(getClass());
    }
}
