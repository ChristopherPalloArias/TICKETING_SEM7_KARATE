# Challenge Metadata
- **Challenge Name:** Ticketing MVP — Karate Expiration and Automatic Release Flow
- **Target System:** Ticketing System for Theatre Events
- **Type of Testing:** Integration / E2E API Flow Validation
- **Level of Effort / Expected Size:** Large

# Challenge Overview
This challenge consists of implementing a Karate DSL API automation for the expiration and automatic release behavior of the Ticketing MVP.

The automation must prove that the system correctly handles reservations that are not successfully completed and that blocked availability is eventually released according to the real backend mechanism.

This feature focuses on the automatic lifecycle after a failed or expired reservation:
- valid event setup
- valid reservation creation
- failed or expired reservation state
- automatic background release
- availability restored for future buyers

This challenge validates one of the most critical business rules of the MVP: preventing inventory from remaining blocked when a buyer does not complete payment successfully.

# API Context
- **Base URL:** To be passed via environment / system property
- **Environment:** Local / Docker Compose QA-like environment
- **Documentation Link:** Not provided

# Environment and Configuration Inputs
- **Required Env Variables:** Optional `KARATE_ENV` if the framework uses environment switching
- **Required System Properties:** `-DbaseUrlEvents`, `-DbaseUrlTicketing`
- **Additional Notes:** This flow may require controlled waiting, runtime observation, or auxiliary validation depending on the real expiration/release mechanism implemented by the backend.

# Authentication and Authorization
- **Auth Type:** Header-based contextual authorization
- **Credentials Provided:** Dummy contextual headers allowed
- **Auth Notes:**
  - Administrative setup uses `X-Role: ADMIN`
  - Event creation may also require `X-User-Id` if confirmed by runtime
  - Buyer flow uses a controlled `X-User-Id`
  - The same `X-User-Id` must be reused consistently during reservation and payment steps

# Endpoints in Scope
| ID | Method | Endpoint | Purpose | Auth Required | Priority | Notes |
|---|---|---|---|---|---|---|
| REQ-01 | POST | `/api/v1/rooms` | Create valid room | Yes | High | Setup |
| REQ-02 | POST | `/api/v1/events` | Create valid event | Yes | High | Setup |
| REQ-03 | POST | `/api/v1/events/{eventId}/tiers` | Configure valid tier | Yes | High | Setup |
| REQ-04 | PATCH | `/api/v1/events/{eventId}/publish` | Publish event | Yes | High | Setup |
| REQ-05 | POST | `/api/v1/reservations` | Create reservation | Yes | Critical | Core setup |
| REQ-06 | POST | `/api/v1/reservations/{reservationId}/payments` | Produce failed payment state when applicable | Yes | Critical | Optional precursor depending on chosen path |
| REQ-07 | Runtime-driven automatic mechanism | Scheduler / background release | No direct API guaranteed | Critical | Must be validated according to real implementation |
| REQ-08 | Availability verification endpoint(s) | Real availability/visibility endpoint if available | Depends | High | Used to prove release effect |
| REQ-09 | SQL validation if required by runtime design | Verify reservation state / availability restoration | N/A | High | Allowed only if necessary for this feature |

# Endpoint Details

## REQ-01 POST `/api/v1/rooms`
- **Purpose:** Create a valid room for event setup
- **Headers:** `X-Role: ADMIN` and any additional header already confirmed by runtime
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
- **Headers:** Real administrative headers required by runtime
- **Path Params:** None
- **Query Params:** None
- **Request Body:** Real event creation contract using `date`, `capacity`, and setup compatible with the chosen release strategy
- **Success Response:** 201 with non-null event identifier
- **Error Response:** Out of scope
- **Key Assertions:** Event ID not null
- **Schema Expectations:** Fuzzy for generated values, strict for business state when relevant
- **Data Dependencies:** Room from REQ-01
- **Cleanup Impact:** None

## REQ-03 POST `/api/v1/events/{eventId}/tiers`
- **Purpose:** Configure valid tier(s) for the event
- **Headers:** Administrative headers required by runtime
- **Path Params:** `eventId`
- **Query Params:** None
- **Request Body:** Real tier configuration contract
- **Success Response:** 201 with non-null tier identifiers
- **Error Response:** Out of scope
- **Key Assertions:** Tier ID not null
- **Schema Expectations:** Fuzzy for generated values
- **Data Dependencies:** Event from REQ-02
- **Cleanup Impact:** None

## REQ-04 PATCH `/api/v1/events/{eventId}/publish`
- **Purpose:** Publish event so that reservation flow becomes available
- **Headers:** Administrative headers required by runtime
- **Path Params:** `eventId`
- **Query Params:** None
- **Request Body:** Empty
- **Success Response:** 200 with state `PUBLISHED`
- **Error Response:** Out of scope
- **Key Assertions:** Event becomes published
- **Schema Expectations:** Strict on business state
- **Data Dependencies:** Event + tier
- **Cleanup Impact:** None

## REQ-05 POST `/api/v1/reservations`
- **Purpose:** Create a valid reservation before expiration/release behavior is exercised
- **Headers:** `X-User-Id`
- **Path Params:** None
- **Query Params:** None
- **Request Body:** Real reservation contract using `eventId`, `tierId`, `buyerEmail`
- **Success Response:** 201 with reservation in `PENDING`
- **Error Response:** Out of scope
- **Key Assertions:** Reservation ID not null, status `PENDING`, validity window populated
- **Schema Expectations:** Fuzzy for IDs and timestamps, strict on status
- **Data Dependencies:** Published event + valid tier
- **Cleanup Impact:** None

## REQ-06 POST `/api/v1/reservations/{reservationId}/payments`
- **Purpose:** Optional path to move reservation into a failed-payment state before automatic release
- **Headers:** `X-User-Id`
- **Path Params:** `reservationId`
- **Query Params:** None
- **Request Body:** Real payment contract using `paymentMethod = MOCK` and `status = DECLINED`
- **Success/Error Response:** Must align with runtime contract already discovered for rejected payment
- **Key Assertions:** Reservation enters the correct intermediate failed-payment state if this path is used
- **Schema Expectations:** Must align with implemented rejected-payment flow
- **Data Dependencies:** Reservation from REQ-05
- **Cleanup Impact:** None

## REQ-07 Automatic Release Mechanism
- **Purpose:** Validate the real background mechanism that releases blocked inventory after expiration or failed-payment lifecycle
- **Headers:** Not applicable if this is a scheduler/background process
- **Path Params:** Not applicable
- **Query Params:** Not applicable
- **Request Body:** Not applicable
- **Success Response:** Not necessarily an HTTP response
- **Error Response:** Not necessarily an HTTP response
- **Key Assertions:** Reservation state changes as expected and availability is restored
- **Schema Expectations:** Runtime/DB/state validation depending on implementation
- **Data Dependencies:** Reservation previously created
- **Cleanup Impact:** None

## REQ-08 Availability Verification
- **Purpose:** Prove that released inventory becomes visible/available again to future buyers
- **Headers:** Depends on endpoint
- **Path Params / Query Params:** Depends on real availability endpoint
- **Request Body:** Depends on endpoint
- **Success Response:** Real contract of availability endpoint
- **Error Response:** Out of scope
- **Key Assertions:** Released quota/availability becomes visible again
- **Schema Expectations:** Based on runtime contract
- **Data Dependencies:** Release must have occurred first
- **Cleanup Impact:** None

## REQ-09 SQL Validation (Allowed if necessary)
- **Purpose:** Verify reservation status and/or availability restoration directly in persistence if the release mechanism cannot be fully proven by HTTP alone
- **Headers:** N/A
- **Path Params:** N/A
- **Query Params:** N/A
- **Request Body:** N/A
- **Success Response:** N/A
- **Error Response:** N/A
- **Key Assertions:** Reservation state, timestamps, release effect, inventory restoration
- **Schema Expectations:** Real table/entity structure only
- **Data Dependencies:** Runtime state already produced
- **Cleanup Impact:** None

# Functional Expectations
This automation must prove one of these real business paths, depending on the backend implementation and testability:

## Path A — Expiration without successful payment
1. create room
2. create event
3. configure tier
4. publish event
5. create reservation
6. let reservation expire according to the real mechanism
7. validate that reservation is no longer active
8. validate that availability is restored

## Path B — Failed payment followed by automatic release
1. create room
2. create event
3. configure tier
4. publish event
5. create reservation
6. process rejected payment
7. validate intermediate failed-payment state
8. validate automatic release by the real mechanism
9. validate availability restored

The implementation must choose the path that is most realistic and stable according to the actual backend design.

# Negative and Edge Cases
- **Negative Testing:** Out of scope beyond the already validated rejected payment path if reused
- **Edge Cases:** Out of scope for this version
- **Important Note:** This feature is focused on the lifecycle and release effect, not on adding multiple rejection variants

# Contract / Schema Validation Expectations
- Setup endpoints should reuse already stabilized contracts from previous implemented flows
- Rejected-payment response should reuse the real runtime contract already discovered if that path is used
- Automatic release validation may require a mixed strategy:
  - response validation,
  - state validation,
  - availability validation,
  - and SQL validation if strictly necessary

# Test Data Strategy
- Controlled `X-User-Id`
- Dynamic buyerEmail
- Dynamic event title
- Future event date
- No seats unless runtime requires them
- Prefer same simple tier strategy already validated
- SQL is allowed only if needed to prove expiration/release state because this feature depends on background processing

# Scenario Dependencies
This feature is sequential by design and depends on prior setup state.
A single orchestrated scenario is acceptable.

# Setup Requirements
Prepare all required data by API:
- create room
- create event
- configure tier
- publish event
- create reservation

If rejected-payment path is used:
- process payment with `DECLINED` using the already validated contract

# Cleanup Requirements
No cleanup required for this challenge iteration unless the environment becomes unstable due to test residue.

# Acceptance Criteria
- [ ] Room is created successfully
- [ ] Event is created successfully
- [ ] Tier is configured successfully
- [ ] Event is published successfully
- [ ] Reservation is created successfully
- [ ] The real expiration/release mechanism is exercised
- [ ] Reservation no longer remains as an active blocked sale
- [ ] Availability is restored according to the real backend behavior
- [ ] Validation is based on the real implementation, not on assumptions
- [ ] SQL may be used only if HTTP/runtime validation is insufficient for this feature

# Risks and Constraints
- The scheduler/background mechanism may not expose a direct HTTP trigger
- Timing may make the test slow or unstable if real waiting is required
- The release effect may be distributed across services
- Availability restoration may be easier to prove through DB state than through HTTP alone
- This feature is inherently more complex than approved/rejected payment because it depends on asynchronous lifecycle behavior

# Tagging and Execution Notes
- **Tags to apply:** `@regression`, `@lifecycle`, `@ticketing`, `@karate`
- **Execution Command:** `mvn test -Dtest=ExpirationReleaseFlowTest`

# Reporting Expectations
Karate HTML report expected in:
```text
target/karate-reports
````

# Assumptions

* Local/docker environment is available
* Direct service endpoints are reachable
* The expiration/release mechanism is active in the runtime
* If a direct business proof is not possible by HTTP, SQL may be required

# Open Questions

* What exact mechanism is used to prove expiration in a stable way?
* Is there a direct endpoint to observe availability restoration?
* Is SQL required to validate the release effect in this implementation?
* Does the scheduler run with a practical cadence for automated testing?

# Out of Scope

* approved payment flow
* basic rejected payment flow already implemented
* concurrency
* seats
* RabbitMQ assertions unless strictly necessary
* performance validation
* gateway auth hardening
