# Challenge Metadata
- **Challenge Name:** Ticketing MVP — Karate Event Availability Visibility
- **Target System:** Ticketing System for Theatre Events
- **Type of Testing:** API Visibility / Availability Validation
- **Level of Effort / Expected Size:** Medium

# Challenge Overview
This challenge consists of implementing Karate automation to validate the buyer-facing availability and visibility behavior of published events and tiers.

The automation must prove:
- events are visible in the buyer availability flow,
- a sold-out tier appears as unavailable,
- an expired Early Bird tier is not shown as an active purchase option,
- and an event with no active tiers does not expose purchase options.

# API Context
- **Base URL:** To be passed via environment / system property
- **Environment:** Local / Docker Compose QA-like environment
- **Documentation Link:** Not provided

# Environment and Configuration Inputs
- **Required Env Variables:** Optional `KARATE_ENV`
- **Required System Properties:** `-DbaseUrlEvents`, `-DbaseUrlTicketing`

# Authentication and Authorization
- **Auth Type:** Public or contextual depending on the actual availability endpoint
- **Credentials Provided:** Not necessarily needed for buyer-facing visibility endpoint
- **Auth Notes:** Use the real runtime endpoint for event visibility/availability

# Endpoints in Scope
| ID | Method | Endpoint | Purpose | Auth Required | Priority | Notes |
|---|---|---|---|---|---|---|
| REQ-01 | GET | Real availability/cartelera endpoint | List visible events/tiers | TBD | Critical | Must be discovered from runtime |
| REQ-02 | POST | `/api/v1/events` and related setup endpoints | Create setup data | Yes | High | Setup only |

# Endpoint Details

## REQ-01 Availability/Visibility Endpoint
- **Purpose:** Show events and/or tier availability to buyer flow
- **Headers:** According to runtime
- **Path Params / Query Params:** According to runtime
- **Success Response:** Real runtime availability contract
- **Error Response:** Out of scope
- **Key Assertions:**
  - visible events are listed,
  - sold-out tier is not exposed as available,
  - expired Early Bird is not active,
  - event with no active tier options has no purchasable tier output
- **Schema Expectations:** Must follow real runtime contract
- **Data Dependencies:** Setup events and tier conditions must be created first

# Functional Expectations
The automation must validate:
1. visible published event with valid availability,
2. tier exhausted or unavailable behavior,
3. expired Early Bird behavior,
4. event with no active purchase options.

# Negative and Edge Cases
- **Negative Testing:** exhaustion/unavailability is part of the feature
- **Edge Cases:** expired Early Bird and no active options are part of the feature

# Contract / Schema Validation Expectations
Use the real availability/cartelera contract exposed by runtime.
Do not invent an availability endpoint if it does not exist.

# Test Data Strategy
- Create event(s) and tier(s) by API
- Manipulate quota and validity windows using real backend behavior only
- If date handling is needed, document the real approach used

# Scenario Dependencies
Independent scenarios are preferred, but controlled sequential setup is acceptable.

# Setup Requirements
Need valid published event(s), tiers, and conditions for sold-out / expired / inactive cases.

# Cleanup Requirements
No cleanup required.

# Acceptance Criteria
- [ ] Visible event appears correctly
- [ ] Sold-out tier is not shown as available
- [ ] Expired Early Bird is not shown as active
- [ ] Event without active tier options does not expose purchase options

# Risks and Constraints
- Availability endpoint may not be obvious
- Early Bird may require date-sensitive setup
- Runtime may expose availability differently than originally expected

# Tagging and Execution Notes
- **Tags to apply:** `@ticketing`, `@availability`, `@visibility`, `@karate`
- **Execution Command:** `mvn test -Dtest=EventAvailabilityVisibilityTest`

# Reporting Expectations
Karate HTML report expected in:
```text
target/karate-reports
Assumptions
A buyer-facing availability endpoint exists in runtime
Published events are exposed through that endpoint
Open Questions
Which exact endpoint should be used for buyer visibility?
How is sold-out represented in runtime?
How is expired Early Bird represented in runtime?
```

# Out of Scope
- UI rendering
- notification behavior
- scheduler internals