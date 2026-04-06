# Challenge Metadata
- **Challenge Name:** Ticketing MVP — Karate Ticket Visibility and Access Control
- **Target System:** Ticketing System for Theatre Events
- **Type of Testing:** Integration / E2E API Flow Validation
- **Level of Effort / Expected Size:** Medium

# Challenge Overview
This challenge consists of implementing Karate DSL API automation to validate ticket visibility, ticket content correctness, absence of successful ticket generation for non-confirmed purchases, and access control over tickets.

The automation must prove that:
- a successful approved purchase produces a visible ticket,
- the ticket contains the expected business information,
- a rejected or non-confirmed purchase does not produce a successful ticket outcome,
- and a different buyer cannot access another buyer’s ticket.

# API Context
- **Base URL:** To be passed via environment / system property
- **Environment:** Local / Docker Compose QA-like environment
- **Documentation Link:** Not provided

# Environment and Configuration Inputs
- **Required Env Variables:** Optional `KARATE_ENV`
- **Required System Properties:** `-DbaseUrlEvents`, `-DbaseUrlTicketing`

# Authentication and Authorization
- **Auth Type:** Header-based contextual authorization
- **Credentials Provided:** Dummy contextual headers allowed
- **Auth Notes:**
  - Administrative setup uses `X-Role: ADMIN`
  - Event creation may require `X-User-Id` according to runtime behavior already observed
  - Buyer flows use `X-User-Id`
  - The same `X-User-Id` must be reused consistently between reservation and payment
  - Ticket access must be validated with owner vs non-owner contexts

# Endpoints in Scope
| ID | Method | Endpoint | Purpose | Auth Required | Priority | Notes |
|---|---|---|---|---|---|---|
| REQ-01 | POST | `/api/v1/rooms` | Create valid room | Yes | High | Setup |
| REQ-02 | POST | `/api/v1/events` | Create valid event | Yes | High | Setup |
| REQ-03 | POST | `/api/v1/events/{eventId}/tiers` | Configure valid tier | Yes | High | Setup |
| REQ-04 | PATCH | `/api/v1/events/{eventId}/publish` | Publish event | Yes | High | Setup |
| REQ-05 | POST | `/api/v1/reservations` | Create reservation | Yes | Critical | Setup for payment |
| REQ-06 | POST | `/api/v1/reservations/{reservationId}/payments` | Process approved or rejected payment | Yes | Critical | Source of ticket/no-ticket outcome |
| REQ-07 | GET | `/api/v1/tickets/{ticketId}` | Retrieve ticket by id | Yes | Critical | Main endpoint under validation |

# Endpoint Details

## REQ-07 GET `/api/v1/tickets/{ticketId}`
- **Purpose:** Retrieve the ticket associated with a successful purchase
- **Headers:** `X-User-Id`
- **Path Params:** `ticketId`
- **Query Params:** None
- **Request Body:** None
- **Success Response:** Real runtime contract for ticket retrieval
- **Error Response:** Real runtime access-control or not-found contract
- **Key Assertions:**
  - successful owner access returns the ticket,
  - the returned ticket contains correct event and purchase information,
  - non-owner access is rejected,
  - non-confirmed purchase does not yield a successful ticket path
- **Schema Expectations:** Fuzzy match for generated values, strict match for business-critical fields
- **Data Dependencies:** Approved purchase must exist first
- **Cleanup Impact:** None

# Functional Expectations
The automation must validate:
1. approved purchase generates ticket successfully,
2. the owner can read the ticket,
3. the ticket business fields are correct,
4. rejected/non-confirmed purchase does not produce a successful ticket retrieval path,
5. another buyer cannot access the owner’s ticket.

# Negative and Edge Cases
- **Negative Testing:** access by non-owner, non-confirmed purchase path
- **Edge Cases:** None required beyond ownership and confirmation state

# Contract / Schema Validation Expectations
Use the real runtime contract of the approved payment response and the GET ticket response.
Do not assume the GET contract is identical to the embedded ticket object returned during payment approval.

# Test Data Strategy
- Dynamic event title
- Dynamic buyer emails
- Controlled owner and non-owner `X-User-Id`
- Setup entirely by API
- No SQL in first implementation unless the GET contract proves insufficient

# Scenario Dependencies
Sequential scenarios are acceptable:
- approved purchase scenario
- rejected purchase scenario
- access control scenario

# Setup Requirements
Prepare event and tier by API, then create reservations and process payments as needed.

# Cleanup Requirements
No cleanup required for this challenge iteration.

# Acceptance Criteria
- [ ] Ticket is visible after approved purchase
- [ ] Ticket fields are correct
- [ ] Rejected or non-confirmed purchase does not produce successful ticket outcome
- [ ] Another buyer cannot access the owner’s ticket

# Risks and Constraints
- Ticket GET contract may differ from ticket embedded in payment approved response
- Ticket access may be protected strictly by `X-User-Id`
- Runtime access control response code must be validated as observed, not assumed

# Tagging and Execution Notes
- **Tags to apply:** `@ticketing`, `@tickets`, `@karate`, `@regression`
- **Execution Command:** `mvn test -Dtest=TicketVisibilityAndAccessControlTest`

# Reporting Expectations
Karate HTML report expected in:
```text
target/karate-reports
Assumptions
The approved flow is already stable
The ticket retrieval endpoint is reachable directly in the test environment
Open Questions
What exact status code does runtime return for non-owner ticket access?
Does rejected payment produce any ticket lookup artifact or simply no ticketId?
```

# Out of Scope
- notification validation
- scheduler behavior
- SQL validation unless strictly needed