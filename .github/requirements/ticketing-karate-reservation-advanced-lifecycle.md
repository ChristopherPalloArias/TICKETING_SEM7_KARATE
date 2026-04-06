# Challenge Metadata
- **Challenge Name:** Ticketing MVP — Karate Reservation Advanced Lifecycle
- **Target System:** Ticketing System for Theatre Events
- **Type of Testing:** Advanced Integration / Lifecycle / Concurrency Validation
- **Level of Effort / Expected Size:** Large

# Challenge Overview
This challenge consists of implementing advanced Karate automation for reservation lifecycle behaviors that go beyond the already implemented approved, rejected, and SQL-based release flows.

The automation must validate advanced lifecycle cases such as:
- reservation expiration without payment,
- payment attempt on an already expired reservation,
- concurrency on the last available slot,
- confirmed purchase not being released by scheduler,
- and backup-job/fallback release behavior if the runtime supports it.

# API Context
- **Base URL:** To be passed via environment / system property
- **Environment:** Local / Docker Compose QA-like environment
- **Documentation Link:** Not provided

# Environment and Configuration Inputs
- **Required Env Variables:** Optional `KARATE_ENV`
- **Required System Properties:** `-DbaseUrlEvents`, `-DbaseUrlTicketing`
- **Possible SQL Support:** Allowed if required by asynchronous runtime design

# Authentication and Authorization
- **Auth Type:** Header-based contextual authorization
- **Credentials Provided:** Dummy contextual headers allowed
- **Auth Notes:** Reuse existing stable setup and SQL helper where useful

# Endpoints in Scope
| ID | Method | Endpoint | Purpose | Auth Required | Priority | Notes |
|---|---|---|---|---|---|---|
| REQ-01 | POST | `/api/v1/reservations` | Create reservations for advanced scenarios | Yes | Critical | Setup |
| REQ-02 | POST | `/api/v1/reservations/{reservationId}/payments` | Process payments in advanced lifecycle cases | Yes | Critical | Main endpoint |
| REQ-03 | SQL / runtime observation | Validate expiration and scheduler effects | N/A | High | Allowed if necessary |
| REQ-04 | Real availability or ownership endpoint | Validate resulting availability or state | TBD | High | Use if available |

# Functional Expectations
The automation must validate:
1. reservation can become expired without successful payment,
2. payment on an expired reservation is rejected,
3. last-slot concurrency does not create over-selling,
4. confirmed purchase is not incorrectly released by the scheduler,
5. backup job or fallback release is validated only if runtime truly exposes it.

# Negative and Edge Cases
- **Negative Testing:** payment on expired reservation
- **Edge Cases:** concurrency, scheduler exclusions, fallback processing

# Contract / Schema Validation Expectations
Use real runtime behavior.
SQL is allowed when asynchronous lifecycle cannot be proven by HTTP alone.

# Test Data Strategy
- Controlled small quota tiers for meaningful lifecycle behavior
- Controlled multiple buyers for concurrency
- SQL helper reuse where necessary

# Scenario Dependencies
Sequential and controlled setup is expected.

# Setup Requirements
Reuse event setup and tier setup by API.

# Cleanup Requirements
No cleanup required unless the environment becomes unstable.

# Acceptance Criteria
- [ ] Expiration without payment is validated
- [ ] Payment on expired reservation is rejected
- [ ] Last-slot concurrency prevents over-selling
- [ ] Confirmed purchase is not released by scheduler
- [ ] Backup/fallback mechanism is validated only if runtime supports it

# Risks and Constraints
- Asynchronous scheduler behavior may require SQL
- Concurrency can be flaky if not designed carefully
- Backup job may not be externally exposed

# Tagging and Execution Notes
- **Tags to apply:** `@ticketing`, `@lifecycle`, `@advanced`, `@karate`
- **Execution Command:** `mvn test -Dtest=ReservationAdvancedLifecycleTest`

# Reporting Expectations
Karate HTML report expected in:
```text
target/karate-reports
Assumptions
The already implemented flows remain stable and reusable
SQL helper can be reused if needed
Open Questions
Which advanced lifecycle cases can be proven entirely by HTTP?
Which require SQL?
Is the backup job externally observable in this runtime?
```

# Out of Scope
- UI-level flows
- notification rendering
- performance validation