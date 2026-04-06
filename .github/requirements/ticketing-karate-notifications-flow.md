# Challenge Metadata
- **Challenge Name:** Ticketing MVP — Karate Notifications Flow
- **Target System:** Ticketing System for Theatre Events
- **Type of Testing:** Integration / API + Event Outcome Validation
- **Level of Effort / Expected Size:** Medium

# Challenge Overview
This challenge consists of implementing Karate automation to validate that the system produces the expected buyer notifications after:
- an approved purchase,
- a rejected payment,
- and an expiration/release flow.

The validation must be based on the real implementation: endpoint-based if a usable notification endpoint exists, or SQL-based if notifications are persisted and HTTP is insufficient.

# API Context
- **Base URL:** To be passed via environment / system property
- **Environment:** Local / Docker Compose QA-like environment
- **Documentation Link:** Not provided

# Environment and Configuration Inputs
- **Required Env Variables:** Optional `KARATE_ENV`
- **Required System Properties:** `-DbaseUrlEvents`, `-DbaseUrlTicketing`
- **Additional SQL Properties if needed:** notification DB connection if runtime requires persistence validation

# Authentication and Authorization
- **Auth Type:** Header-based contextual authorization
- **Credentials Provided:** Dummy contextual headers allowed
- **Auth Notes:**
  - Reuse approved, rejected, and expiration flows already implemented or stabilized
  - Notification validation may require buyer identity context or SQL

# Endpoints in Scope
| ID | Method | Endpoint | Purpose | Auth Required | Priority | Notes |
|---|---|---|---|---|---|---|
| REQ-01 | POST | `/api/v1/reservations/{reservationId}/payments` | Produce approved or rejected outcomes | Yes | Critical | Input event that should trigger notifications |
| REQ-02 | GET | `/api/v1/notifications/buyer/{id}` | Read notifications if endpoint is usable | Depends | High | Use only if confirmed by runtime |
| REQ-03 | SQL validation | notification persistence | Validate notification records if endpoint is insufficient | N/A | High | Allowed if runtime design requires it |

# Endpoint Details

## REQ-02 GET `/api/v1/notifications/buyer/{id}`
- **Purpose:** Retrieve notifications for a buyer
- **Headers:** According to real runtime behavior
- **Path Params:** `id`
- **Success Response:** Real notification list contract if available
- **Error Response:** Runtime real behavior
- **Key Assertions:** Notification exists for approved, rejected, and release scenarios
- **Schema Expectations:** Must be based on runtime
- **Data Dependencies:** Prior business events must already have occurred

# Functional Expectations
The automation must validate:
1. buyer receives approved-purchase notification,
2. buyer receives rejected-payment notification,
3. buyer receives expiration/release notification.

# Negative and Edge Cases
- **Negative Testing:** Not required beyond the three business outcomes
- **Edge Cases:** None required in first implementation

# Contract / Schema Validation Expectations
Prefer real notification endpoint if stable.
If the endpoint is not stable or not sufficient, validate persistence by SQL.

# Test Data Strategy
- Reuse already implemented flows:
  - approved purchase
  - rejected payment
  - expiration/release path B
- Buyer identities should be controlled and traceable

# Scenario Dependencies
Sequential scenarios are acceptable and expected.

# Setup Requirements
Reuse stable setup from previously implemented features.

# Cleanup Requirements
No cleanup required.

# Acceptance Criteria
- [ ] Notification evidence exists for approved purchase
- [ ] Notification evidence exists for rejected payment
- [ ] Notification evidence exists for expiration/release

# Risks and Constraints
- Notification system may be asynchronous
- Notification validation may require waiting or SQL
- Real notification endpoint may be partial or inconvenient

# Tagging and Execution Notes
- **Tags to apply:** `@ticketing`, `@notifications`, `@karate`, `@regression`
- **Execution Command:** `mvn test -Dtest=NotificationsFlowTest`

# Reporting Expectations
Karate HTML report expected in:
```text
target/karate-reports
Assumptions
Notification generation exists in runtime
There is either a usable endpoint or a persistent record we can validate
Open Questions
Is the notification endpoint sufficiently exposed for automation?
Which exact notification table/fields should be used if SQL is required?
```

# Out of Scope
- UI/email rendering
- message formatting beyond business presence/meaning
- performance validation