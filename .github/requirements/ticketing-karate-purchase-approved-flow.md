# Challenge Metadata
- **Challenge Name:** Ticketing MVP — Karate Approved Purchase Flow
- **Target System:** Ticketing System for Theatre Events
- **Type of Testing:** Integration / E2E API Flow Validation
- **Level of Effort / Expected Size:** Medium

# Challenge Overview
This challenge consists of implementing a stable Karate DSL API automation for the main happy path of the Ticketing MVP purchase flow.

The automation must prove that the system is capable of preparing the minimum business data required for a sale, creating a reservation for a buyer, and processing a simulated approved payment that ends with a confirmed purchase and generated ticket.

The solution must use the real contracts and behaviors detected in the audited microservices codebase. The focus of this first feature is stability, correctness, and alignment with the actual implementation, not maximum coverage.

This challenge represents the core transactional value of the MVP:
- valid event available for sale,
- valid tier configuration,
- reservation creation,
- approved payment processing,
- confirmed purchase with ticket generation.

# API Context
- **Base URL:** To be passed via environment / system property
- **Environment:** Local / Docker Compose QA-like environment
- **Documentation Link:** Not provided

# Environment and Configuration Inputs
- **Required Env Variables:** Optional `KARATE_ENV` if the framework uses environment switching
- **Required System Properties:** `-DbaseUrlEvents`, `-DbaseUrlTicketing`
- **Additional Notes:** The solution should be prepared to target `ms-events` and `ms-ticketing` directly, without depending on the API Gateway for the first happy path flow.

# Authentication and Authorization
- **Auth Type:** Header-based contextual authorization
- **Credentials Provided:** Dummy contextual headers allowed
- **Auth Notes:**  
  - Administrative setup endpoints require admin context, using the real header mechanism detected in the service, specifically `X-Role: ADMIN` or the exact equivalent validated by implementation.
  - Buyer flow endpoints must reuse the same `X-User-Id` value between reservation creation and payment processing.
  - The first implementation must avoid relying on JWT negotiation or API Gateway guest path rules unless strictly necessary.

# Endpoints in Scope
| ID | Method | Endpoint | Purpose | Auth Required | Priority | Notes |
|---|---|---|---|---|---|---|
| REQ-01 | POST | `/api/v1/rooms` | Create a valid room for event setup | Yes | High | Setup step |
| REQ-02 | POST | `/api/v1/events` | Create a valid event in DRAFT state | Yes | High | Setup step |
| REQ-03 | POST | `/api/v1/events/{eventId}/tiers` | Configure a valid tier for the event | Yes | High | Setup step |
| REQ-04 | PATCH | `/api/v1/events/{eventId}/publish` | Publish the event so it becomes sellable | Yes | High | Setup step |
| REQ-05 | POST | `/api/v1/reservations` | Create a buyer reservation | Yes | Critical | Main business action |
| REQ-06 | POST | `/api/v1/reservations/{reservationId}/payments` | Process approved mock payment | Yes | Critical | Main business action |

# Endpoint Details

## REQ-01 POST `/api/v1/rooms`
- **Purpose:** Create a valid room that can later be used to create an event with sufficient capacity.
- **Headers:** Administrative context header required, expected as `X-Role: ADMIN` or exact equivalent confirmed by implementation.
- **Path Params:** None
- **Query Params:** None
- **Request Body:** Must match the real room creation contract from the codebase. The spec must use only real fields detected in the room DTO/controller/service.
- **Success Response:** Expected successful creation response with generated room identifier and max capacity information.
- **Error Response:** Validation errors if mandatory fields are missing or inconsistent.
- **Key Assertions:** Room identifier must not be null. Capacity-related fields must reflect the request contract.
- **Schema Expectations:** Fuzzy match allowed for generated IDs and timestamps, strict match for business fields explicitly set by the test.
- **Data Dependencies:** None
- **Cleanup Impact:** No cleanup required for the first implementation unless the framework demands explicit teardown.

## REQ-02 POST `/api/v1/events`
- **Purpose:** Create an event associated with the newly created room.
- **Headers:** Administrative context header required, expected as `X-Role: ADMIN`.
- **Path Params:** None
- **Query Params:** None
- **Request Body:** Real `EventCreateRequest` contract detected from code. Must include only valid fields from implementation.
- **Success Response:** Event creation response with generated `eventId` and initial state equivalent to `DRAFT`.
- **Error Response:** Validation or business errors such as capacity exceeding room capacity, duplicated event, invalid date, or forbidden access.
- **Key Assertions:** Event ID must not be null. Event must be created in draft-like initial state. Room association must be valid.
- **Schema Expectations:** Fuzzy match for generated technical values, strict match for core business input.
- **Data Dependencies:** Requires a previously created room from REQ-01.
- **Cleanup Impact:** None for the first version.

## REQ-03 POST `/api/v1/events/{eventId}/tiers`
- **Purpose:** Configure a valid tier for the event so it becomes eligible for reservation.
- **Headers:** Administrative context header required, expected as `X-Role: ADMIN`.
- **Path Params:** `eventId`
- **Query Params:** None
- **Request Body:** Real list of `TierCreateRequest` objects. For the first feature, use a single valid `GENERAL` tier with valid `price` and `quota`.
- **Success Response:** Tier configuration response containing created tier identifiers.
- **Error Response:** Validation or business errors such as duplicated tier type, quota exceeding capacity, event already initialized, or forbidden access.
- **Key Assertions:** Response must contain at least one tier. The created tier must have a non-null ID and expected type.
- **Schema Expectations:** Fuzzy match for IDs and timestamps, strict match for tier type and numeric business fields.
- **Data Dependencies:** Requires `eventId` from REQ-02.
- **Cleanup Impact:** None for the first version.

## REQ-04 PATCH `/api/v1/events/{eventId}/publish`
- **Purpose:** Transition the event from draft state to published state.
- **Headers:** Administrative context header required, expected as `X-Role: ADMIN`.
- **Path Params:** `eventId`
- **Query Params:** None
- **Request Body:** No body expected.
- **Success Response:** Event response showing published state.
- **Error Response:** Validation or business errors if the event is not in draft state, has no tiers, or caller lacks admin permissions.
- **Key Assertions:** Event status must become `PUBLISHED` or exact equivalent from implementation.
- **Schema Expectations:** Strict match for state transition.
- **Data Dependencies:** Requires event and at least one configured tier from REQ-02 and REQ-03.
- **Cleanup Impact:** None for the first version.

## REQ-05 POST `/api/v1/reservations`
- **Purpose:** Create a valid reservation for a buyer against a published event and valid tier.
- **Headers:** `X-User-Id` must be explicitly controlled by the test and reused later in payment.
- **Path Params:** None
- **Query Params:** None
- **Request Body:** Real `CreateReservationRequest` contract:
  - `eventId`
  - `tierId`
  - `buyerEmail`
  - `seatIds` optional and not to be used in this first feature
- **Success Response:** `ReservationResponse` with non-null reservation ID and reservation status equivalent to `PENDING`.
- **Error Response:** `400` for invalid body or invalid email, business validation failures if event is not published, tier mismatch, or seat/quota issues.
- **Key Assertions:** Reservation ID must not be null, status must be `PENDING` or equivalent, returned `eventId` and `tierId` must match the request, `buyerId` must be present, and validity window field must be populated.
- **Schema Expectations:** Fuzzy match for generated values and timestamps, strict match for request-driven business values.
- **Data Dependencies:** Requires published event and valid tier from REQ-04.
- **Cleanup Impact:** None for the first version.

## REQ-06 POST `/api/v1/reservations/{reservationId}/payments`
- **Purpose:** Process an approved mock payment for the created reservation.
- **Headers:** Same exact `X-User-Id` used in REQ-05.
- **Path Params:** `reservationId`
- **Query Params:** None
- **Request Body:** Real `PaymentRequest` contract:
  - `amount`
  - `paymentMethod`
  - `status`
  
  For this first feature, the request must use:
  - valid positive amount
  - `paymentMethod = MOCK`
  - `status = APPROVED`
- **Success Response:** `PaymentResponse` indicating confirmed reservation/purchase and generated ticket.
- **Error Response:** Validation errors, fraud/forbidden access if buyer ownership mismatches, expired reservation, invalid payment status, max attempts exceeded, or optimistic locking conflict.
- **Key Assertions:** Reservation status must become `CONFIRMED` or equivalent, `ticketId` must not be null, response message must indicate successful payment or purchase confirmation, and nested ticket object must be present if the real contract returns it.
- **Schema Expectations:** Fuzzy match for generated IDs and timestamps, strict match for core business status fields.
- **Data Dependencies:** Requires reservation from REQ-05 and same owner identity header.
- **Cleanup Impact:** None for the first version.

# Functional Expectations
The automation must prove the full happy path of approved purchase with setup by API:
1. A room is created successfully.
2. An event is created successfully in draft state.
3. A valid GENERAL tier is configured.
4. The event is published.
5. A reservation is created successfully with buyer email and controlled `X-User-Id`.
6. The reservation is paid successfully using the same `X-User-Id`.
7. The final payment response proves that a ticket was generated and the purchase was confirmed.

# Negative and Edge Cases
- **Negative Testing:** Out of scope for this first feature.
- **Edge Cases:** Out of scope for this first feature. The first implementation must only stabilize the main approved purchase flow.

# Contract / Schema Validation Expectations
The main responses should use schema-style assertions consistent with Karate best practices:
- IDs: `#uuid` or equivalent fuzzy assertion
- Strings: `#string`
- Timestamps: `#string` or equivalent if format-specific validation is not yet stabilized
- Numeric fields: `#number`
- Nested ticket object: fuzzy structure validation is acceptable in this first version

The feature must prioritize stable contract verification over exhaustive schema rigidity.

# Test Data Strategy
The strategy must use controlled and mostly dynamic data generated inside the framework:
- `X-User-Id`: generated once and reused through the scenario
- `buyerEmail`: deterministic but unique-friendly, e.g. time-suffixed email if needed
- `title`: unique enough to avoid duplicate business validations
- future event date
- valid capacity and quota values that do not create pressure on inventory

No SQL-based data setup must be used in this first feature.

# Scenario Dependencies
This first feature is intentionally sequential and dependent by design:
- room creation is required before event creation
- event creation is required before tier configuration
- tier configuration is required before publish
- publish is required before reservation
- reservation is required before payment

This first implementation does not require full scenario independence. A single orchestrated happy-path scenario is acceptable and expected.

# Setup Requirements
The feature must prepare all required data by API in the same scenario or through reusable helper/background calls:
- create room
- create event
- configure tier
- publish event

Administrative setup must use the correct admin header context required by the real implementation.

# Cleanup Requirements
No cleanup is required for the first implementation unless the project framework already has a standard teardown strategy.
This first feature may leave created records in the environment if that is acceptable for the local/docker challenge context.

# Acceptance Criteria
- [ ] The automation successfully creates a room using the real API contract.
- [ ] The automation successfully creates an event using the real API contract.
- [ ] The automation successfully configures at least one valid tier for the event.
- [ ] The automation successfully publishes the event.
- [ ] The automation successfully creates a reservation with a controlled `X-User-Id`.
- [ ] The automation successfully processes a mock approved payment using the same `X-User-Id`.
- [ ] The final response proves confirmed purchase and ticket generation.
- [ ] The implementation does not use SQL, scheduler, seats, RabbitMQ validations, or negative scenarios in this first version.

# Risks and Constraints
- The buyer identity header must remain exactly the same between reservation creation and payment. Otherwise the system may detect forbidden access or fraud.
- The event must be published before reservation creation. Draft events are not valid for ticketing flow.
- The API Gateway may introduce restrictions for GET endpoints in guest-like flows, so this first feature must not depend on `GET /tickets/{ticketId}` unless confirmed stable by implementation.
- The setup depends on the availability of both `ms-events` and `ms-ticketing`.
- Event titles and dates must avoid duplicate business rules.

# Tagging and Execution Notes
- **Tags to apply:** `@smoke`, `@happyPath`, `@ticketing`, `@karate`
- **Execution Command:** `mvn test -Dtest=TicketingRunner`

# Reporting Expectations
Karate HTML reporting is expected under:
```text
target/karate-reports
````

# Assumptions

* The local/docker environment is available and all required services are up.
* The direct service endpoints for `ms-events` and `ms-ticketing` are reachable.
* Admin setup endpoints accept the detected role header context.
* The payment happy path is stable enough to validate by response contract only.
* Seat-based purchase is not required for the first implementation.

# Open Questions

* What is the exact DTO contract for `POST /api/v1/rooms`?
* What is the exact room response structure returned by the implementation?
* Should the first feature hit direct services or the gateway once the flow is stabilized?
* Is there an existing naming convention in the framework for helper setup features such as `CreateRoom.feature` or `CreateEvent.feature`?

# Out of Scope

The following are explicitly out of scope for this first feature:

* rejected payment flow
* reservation expiration
* scheduler validation
* automatic release flow
* notification verification
* RabbitMQ assertions
* SQL assertions
* concurrency
* seat-based booking
* API Gateway authorization flow hardening
* performance validation
* contract-negative scenarios