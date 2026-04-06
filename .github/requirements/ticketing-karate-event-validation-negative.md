# Challenge Metadata
- **Challenge Name:** Ticketing MVP — Karate Event Validation Negative
- **Target System:** Ticketing System for Theatre Events
- **Type of Testing:** Negative API Validation
- **Level of Effort / Expected Size:** Small

# Challenge Overview
This challenge consists of implementing Karate automation for negative validations when creating events.

The automation must prove the backend rejects:
- event capacity above room maximum,
- event creation without required date,
- event creation with multiple missing required fields.

# API Context
- **Base URL:** To be passed via environment / system property
- **Environment:** Local / Docker Compose QA-like environment
- **Documentation Link:** Not provided

# Environment and Configuration Inputs
- **Required Env Variables:** Optional `KARATE_ENV`
- **Required System Properties:** `-DbaseUrlEvents`

# Authentication and Authorization
- **Auth Type:** Header-based administrative authorization
- **Credentials Provided:** Dummy contextual headers allowed
- **Auth Notes:** Reuse valid room setup, then execute negative event creation attempts

# Endpoints in Scope
| ID | Method | Endpoint | Purpose | Auth Required | Priority | Notes |
|---|---|---|---|---|---|---|
| REQ-01 | POST | `/api/v1/rooms` | Create valid room | Yes | High | Setup |
| REQ-02 | POST | `/api/v1/events` | Negative event creation validations | Yes | Critical | Main endpoint |

# Functional Expectations
The automation must validate:
1. rejection when event capacity exceeds room maxCapacity,
2. rejection when date is missing,
3. rejection when multiple required fields are missing.

# Negative and Edge Cases
- **Negative Testing:** This feature itself is negative validation
- **Edge Cases:** None beyond missing/invalid required fields

# Contract / Schema Validation Expectations
Validate real runtime status code and error behavior.
Do not assume a strict error schema if backend does not provide one consistently.

# Test Data Strategy
- Valid room setup
- Invalid event bodies per scenario

# Scenario Dependencies
Each scenario can reuse independent room setup or shared room setup if stable.

# Setup Requirements
Need valid room creation first.

# Cleanup Requirements
No cleanup required.

# Acceptance Criteria
- [ ] Capacity above room max is rejected
- [ ] Missing date is rejected
- [ ] Multiple missing mandatory fields are rejected

# Risks and Constraints
- Error message may vary
- Runtime may return validation details differently across scenarios

# Tagging and Execution Notes
- **Tags to apply:** `@ticketing`, `@validation`, `@negative`, `@karate`
- **Execution Command:** `mvn test -Dtest=EventValidationNegativeTest`

# Reporting Expectations
Karate HTML report expected in:
```text
target/karate-reports
Assumptions
Room creation remains stable
Event validation rules match the audited implementation
Open Questions
Which exact status code does runtime return in each invalid case?
Are validation error messages consistent enough to assert text?
```

# Out of Scope
- tier validation
- purchase flows
- notifications