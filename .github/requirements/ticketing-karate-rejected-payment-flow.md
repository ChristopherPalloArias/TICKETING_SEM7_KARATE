# Challenge Metadata
- **Challenge Name:** Ticketing MVP — Karate Rejected Payment Flow
- **Target System:** Ticketing System for Theatre Events
- **Type of Testing:** Integration / E2E API Flow Validation
- **Level of Effort / Expected Size:** Medium

# Challenge Overview
This challenge consists of implementing a Karate DSL API automation for the rejected payment path of the Ticketing MVP purchase flow.

The automation must prove that the system is capable of preparing the minimum valid business data required for a sale, creating a valid reservation for a buyer, and then processing a simulated rejected payment so that the purchase is not confirmed and no successful ticket confirmation is produced.

This challenge validates the negative business outcome of the payment stage while reusing the same stable setup already proven in the approved purchase flow.

# API Context
- **Base URL:** To be passed via environment / system property
- **Environment:** Local / Docker Compose QA-like environment
- **Documentation Link:** Not provided

# Environment and Configuration Inputs
- **Required Env Variables:** Optional `KARATE_ENV` if the framework uses environment switching
- **Required System Properties:** `-DbaseUrlEvents`, `-DbaseUrlTicketing`

# Authentication and Authorization
- **Auth Type:** Header-based contextual authorization
- **Credentials Provided:** Dummy contextual headers allowed
- **Auth Notes:**
  - Administrative setup uses `X-Role: ADMIN`
  - Buyer flow uses a controlled `X-User-Id`
  - The same `X-User-Id` must be reused between reservation creation and rejected payment processing

# Endpoints in Scope
| ID | Method | Endpoint | Purpose | Auth Required | Priority | Notes |
|---|---|---|---|---|---|---|
| REQ-01 | POST | `/api/v1/rooms` | Create valid room | Yes | High | Setup |
| REQ-02 | POST | `/api/v1/events` | Create valid event | Yes | High | Setup |
| REQ-03 | POST | `/api/v1/events/{eventId}/tiers` | Configure valid GENERAL tier | Yes | High | Setup |
| REQ-04 | PATCH | `/api/v1/events/{eventId}/publish` | Publish event | Yes | High | Setup |
| REQ-05 | POST | `/api/v1/reservations` | Create valid reservation | Yes | Critical | Main setup for negative payment |
| REQ-06 | POST | `/api/v1/reservations/{reservationId}/payments` | Process rejected mock payment | Yes | Critical | Main business validation |

# Endpoint Details

## REQ-01 POST `/api/v1/rooms`
- **Purpose:** Create valid room for event setup
- **Headers:** `X-Role: ADMIN`
- **Path Params:** None
- **Query Params:** None
- **Request Body:** Real room creation contract from implementation
- **Success Response:** 201 with non-null room identifier
- **Error Response:** Out of scope for this feature
- **Key Assertions:** Room ID not null
- **Schema Expectations:** Fuzzy for generated values
- **Data Dependencies:** None
- **Cleanup Impact:** None

## REQ-02 POST `/api/v1/events`
- **Purpose:** Create valid event associated with room
- **Headers:** `X-Role: ADMIN`, plus any additional required header already confirmed by runtime
- **Path Params:** None
- **Query Params:** None
- **Request Body:** Real event creation contract using `date`, `capacity`, `enableSeats: false`
- **Success Response:** 201 with non-null event identifier and internal initial state
- **Error Response:** Out of scope
- **Key Assertions:** Event ID not null
- **Schema Expectations:** Fuzzy for generated fields, strict for expected business state
- **Data Dependencies:** Room from REQ-01
- **Cleanup Impact:** None

## REQ-03 POST `/api/v1/events/{eventId}/tiers`
- **Purpose:** Configure valid GENERAL tier
- **Headers:** `X-Role: ADMIN`
- **Path Params:** `eventId`
- **Query Params:** None
- **Request Body:** Real tier configuration contract using `tierType`, `price`, `quota`
- **Success Response:** 201 with non-null tier identifier
- **Error Response:** Out of scope
- **Key Assertions:** Tier ID not null, tier type GENERAL
- **Schema Expectations:** Fuzzy for generated values
- **Data Dependencies:** Event from REQ-02
- **Cleanup Impact:** None

## REQ-04 PATCH `/api/v1/events/{eventId}/publish`
- **Purpose:** Publish event
- **Headers:** `X-Role: ADMIN`
- **Path Params:** `eventId`
- **Query Params:** None
- **Request Body:** Empty
- **Success Response:** 200 with state `PUBLISHED`
- **Error Response:** Out of scope
- **Key Assertions:** Status is `PUBLISHED`
- **Schema Expectations:** Strict on state
- **Data Dependencies:** Event + tier
- **Cleanup Impact:** None

## REQ-05 POST `/api/v1/reservations`
- **Purpose:** Create valid reservation before payment
- **Headers:** `X-User-Id`
- **Path Params:** None
- **Query Params:** None
- **Request Body:** `eventId`, `tierId`, `buyerEmail`
- **Success Response:** 201 with reservation in `PENDING`
- **Error Response:** Out of scope
- **Key Assertions:** Reservation ID not null, status `PENDING`, validity window populated
- **Schema Expectations:** Fuzzy for IDs and timestamps, strict on status
- **Data Dependencies:** Published event + valid tier
- **Cleanup Impact:** None

## REQ-06 POST `/api/v1/reservations/{reservationId}/payments`
- **Purpose:** Process rejected mock payment
- **Headers:** Same exact `X-User-Id` used in reservation creation
- **Path Params:** `reservationId`
- **Query Params:** None
- **Request Body:** Real payment contract using:
  - valid positive amount
  - `paymentMethod = MOCK`
  - `status = DECLINED`
- **Success Response:** Real rejected-payment contract returned by runtime
- **Error Response:** Business rejection aligned with implementation
- **Key Assertions:** Payment must not confirm purchase, must not return successful confirmed contract, and must reflect rejected/failed outcome according to runtime behavior
- **Schema Expectations:** Must be based on actual runtime contract, not assumptions
- **Data Dependencies:** Reservation from REQ-05
- **Cleanup Impact:** None

# Functional Expectations
The automation must prove this sequence:
1. room creation
2. event creation
3. tier configuration
4. event publication
5. reservation creation
6. rejected payment processing

The final validation must prove that the payment is rejected and that the purchase is not confirmed.

# Negative and Edge Cases
- **Negative Testing:** This feature itself represents the negative business path of payment rejection.
- **Edge Cases:** Out of scope

# Contract / Schema Validation Expectations
The response of the rejected payment step must be validated using the actual runtime contract returned by the backend.
Do not assume that rejected payment has the same response shape as approved payment.

# Test Data Strategy
- Controlled `X-User-Id`
- Dynamic buyerEmail
- Dynamic event title
- Future date
- No SQL
- No scheduler
- No seats

# Scenario Dependencies
Single sequential scenario is expected and acceptable.

# Setup Requirements
Prepare all data by API in the same scenario or reusable helper flow.

# Cleanup Requirements
No cleanup required for this first rejected-payment implementation.

# Acceptance Criteria
- [ ] Room is created successfully
- [ ] Event is created successfully
- [ ] Tier is configured successfully
- [ ] Event is published successfully
- [ ] Reservation is created successfully
- [ ] Rejected payment is processed using `status = DECLINED`
- [ ] Final validation proves payment rejection and absence of confirmed purchase contract

# Risks and Constraints
- Same `X-User-Id` must be reused between reservation creation and payment
- Event must be published before reservation
- Rejected payment response shape must be discovered from runtime if not fully documented
- This feature must not use SQL, RabbitMQ, expiration, scheduler, or seats

# Tagging and Execution Notes
- **Tags to apply:** `@smoke`, `@negativeBusinessPath`, `@ticketing`, `@karate`
- **Execution Command:** `mvn test -Dtest=PaymentRejectedFlowTest`

# Reporting Expectations
Karate HTML report expected in:
```text
target/karate-reports
````

# Assumptions

* Local/docker environment is available
* Direct service endpoints are reachable
* Rejected payment with `MOCK + DECLINED` is supported by implementation

# Open Questions

* What exact HTTP status and response body does runtime return for rejected payment?
* Does runtime return a structured error payload or a business response payload?

# Out of Scope

* approved payment
* expiration
* scheduler
* automatic release
* RabbitMQ assertions
* SQL assertions
* concurrency
* seats
* gateway auth hardening
