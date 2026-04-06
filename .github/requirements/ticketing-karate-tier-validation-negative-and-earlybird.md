# Challenge Metadata
- **Challenge Name:** Ticketing MVP — Karate Tier Validation Negative and Early Bird
- **Target System:** Ticketing System for Theatre Events
- **Type of Testing:** Negative API Validation / Temporal Business Rule Validation
- **Level of Effort / Expected Size:** Medium

# Challenge Overview
This challenge consists of implementing Karate automation to validate tier configuration negative cases and the business behavior of Early Bird validity windows.

The automation must prove:
- invalid prices are rejected,
- quota above event capacity is rejected,
- and Early Bird is only active within its valid time window.

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
- **Auth Notes:** Requires valid room and event setup before tier configuration

# Endpoints in Scope
| ID | Method | Endpoint | Purpose | Auth Required | Priority | Notes |
|---|---|---|---|---|---|---|
| REQ-01 | POST | `/api/v1/events/{eventId}/tiers` | Configure or reject tier configurations | Yes | Critical | Main endpoint |
| REQ-02 | GET | Real availability endpoint if needed | Validate Early Bird active/inactive behavior | TBD | High | Use only if required by runtime |

# Functional Expectations
The automation must validate:
1. invalid price is rejected,
2. quota above capacity is rejected,
3. Early Bird behaves correctly within and outside its window.

# Negative and Edge Cases
- **Negative Testing:** invalid price and quota overflow
- **Edge Cases:** Early Bird temporal behavior

# Contract / Schema Validation Expectations
Use real runtime status codes and messages.
Do not invent temporal controls if runtime does not support them directly.

# Test Data Strategy
- Valid room and event setup
- Invalid tier payloads
- Controlled Early Bird window setup if supported

# Scenario Dependencies
Event setup required first.

# Setup Requirements
Need event created before tier configuration.

# Cleanup Requirements
No cleanup required.

# Acceptance Criteria
- [ ] Invalid price is rejected
- [ ] Quota exceeding capacity is rejected
- [ ] Early Bird active/inactive behavior is validated

# Risks and Constraints
- Early Bird may require time-sensitive validation
- Runtime may not expose a trivial way to simulate time
- Availability endpoint may be required to observe Early Bird behavior

# Tagging and Execution Notes
- **Tags to apply:** `@ticketing`, `@tiers`, `@negative`, `@earlybird`, `@karate`
- **Execution Command:** `mvn test -Dtest=TierValidationNegativeAndEarlyBirdTest`

# Reporting Expectations
Karate HTML report expected in:
```text
target/karate-reports
Assumptions
Tier configuration endpoint supports Early Bird business setup
Event setup remains stable
Open Questions
How is Early Bird visibility observed in runtime?
Is date simulation required or can it be configured directly through payload timing?
```

# Out of Scope
- purchase confirmation
- notifications
- scheduler behavior