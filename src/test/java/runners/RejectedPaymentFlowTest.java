package runners;

import com.intuit.karate.junit5.Karate;

public class RejectedPaymentFlowTest {
    
    @Karate.Test
    Karate testRejectedPaymentFlow() {
        return Karate.run("classpath:api/rejected-payment-flow/rejected-payment-flow.feature").relativeTo(getClass());
    }
}
