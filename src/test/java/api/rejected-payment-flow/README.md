# Ticketing MVP - Rejected Payment Flow Automation

## Overview
This is a complete end-to-end Karate automation for the negative business path of rejected payment in the Ticketing MVP, validating:
- Complete setup (Room → Event → Tier → Publish → Reservation) identical to approved flow
- Reservation creation with PENDING status
- **Payment processing with status `DECLINED`**
- **Validation that payment is rejected (no ticket, no confirmed purchase)**

## Feature File
- **Location**: `src/test/java/api/rejected-payment-flow/rejected-payment-flow.feature`
- **Scenario**: Complete Flow with Rejected Payment
- **Focus**: Negative business path (payment rejection)

## Key Differences from Approved Flow

| Aspect | Approved Flow | Rejected Flow |
|--------|---------------|---------------|
| Payment Status | `APPROVED` | `DECLINED` |
| Expected Outcome | Purchase confirmed, ticket generated | Payment rejected, no ticket, no confirmation |
| Final Assertion | `/payments` returns ticketId | `/payments` returns rejection, NO ticketId |
| Reservation Status | Changes to `CONFIRMED` | Remains in status that indicates rejection |

## Running the Tests

### Prerequisites
- Maven 3.6+
- JDK 11+
- Karate framework configured in pom.xml
- Local/Docker services running:
  - `ms-events` on default port (or via -DbaseUrlEvents)
  - `ms-ticketing` on default port (or via -DbaseUrlTicketing)

### Execution

#### Option 1: Default (Single Base URL)
```bash
mvn test -Dtest=RejectedPaymentFlowTest -DbaseUrl=http://localhost:8080
```

#### Option 2: Separate Service URLs
```bash
mvn test -Dtest=RejectedPaymentFlowTest \
  -DbaseUrlEvents=http://localhost:8081 \
  -DbaseUrlTicketing=http://localhost:8082
```

#### Option 3: Run All Tests
```bash
mvn test
```

## Test Data
- **Generated Dynamically** at runtime:
  - `buyerId`: Random UUID, reused between reservation and payment
  - `buyerEmail`: Timestamp-based unique email
  - `eventTitle`: Timestamp-based unique event name
  - `X-User-Id`: Same buyerId used in both reservation creation and rejected payment
- **No SQL or database setup required**

## Assets Used
- **Payloads**:
  - `src/test/java/common/payloads/room-create-request.json` (reused)
  - `src/test/java/common/payloads/event-create-request.json` (reused)
  - `src/test/java/common/payloads/tiers-create-request.json` (reused)
  - `src/test/java/common/payloads/reservation-create-request.json` (reused)
  - `src/test/java/common/payloads/payment-declined-request.json` (**NEW**)

- **Schemas**:
  - Various response schemas reused from approved flow
  - `src/test/java/common/schemas/payment-declined-response.json` (**NEW**, flexible schema)

## Critical Validations in Feature

### Setup Phase (HU-01 to HU-05)
- ✓ Room created (201, id not null)
- ✓ Event created in DRAFT (201, status = DRAFT)
- ✓ Tier configured (201, tierId not null, tierType = GENERAL)
- ✓ Event published (200, status = PUBLISHED)
- ✓ Reservation created PENDING (201, status = PENDING, same buyerId)

### Rejection Phase (HU-06 - CRITICAL)
- ✓ Payment sent with `status: DECLINED`
- ✓ Response contains reservation data
- ❌ **NO ticketId in response** (or ticketId is null/empty)
- ❌ **Status is NOT `CONFIRMED`**
- ✓ Response indicates rejection (various formats possible, contract to be discovered)

## Expected Output

```
Scenario: Complete Flow with Rejected Payment
  Setup:
    - Room created ✓
    - Event created DRAFT ✓
    - Tier configured ✓
    - Event published ✓
    - Reservation created PENDING ✓
  
  Rejection Phase:
    - Payment sent with DECLINED status ✓
    - Response indicates rejection ✓
    - NO ticket generated ✓
    - NO purchase confirmation ✓
    
Validation passed: Payment correctly rejected, no ticket generated ✓
```

## Contract Discovery Notes

The exact HTTP status and response shape for rejected payments is **runtime-dependent**. The feature:

1. **Accepts any HTTP status** (200, 400, 402, etc.) - will be logged
2. **Uses flexible assertions** for response structure
3. **Validates critical business rules** instead of fixed contracts:
   - `ticketId` must be absent or null
   - Status must NOT be `CONFIRMED`
   - Response must indicate rejection

After first execution, update `src/test/java/common/schemas/payment-declined-response.json` with the discovered contract.

## Troubleshooting

1. **Connection Refused**: Ensure services running on correct ports
2. **201 vs 400 for rejected payment**: Discover in runtime, update assertions
3. **ticketId field name**: May differ from approved flow (discovered in runtime)
4. **Same buyerId validation**: Confirm `X-User-Id` header matches between reservation and payment
5. **Response contract unknown**: Log the response, adjust schema, commit updated schema

## Related Documentation
- **Spec (APPROVED v1.1)**: `.github/specs/ticketing-karate-rejected-payment-flow.spec.md`
- **Requirements**: `.github/requirements/ticketing-karate-rejected-payment-flow.md`
- **Approved Flow Reference**: See `src/test/java/api/purchase-approved-flow/`
