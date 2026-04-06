# Challenge Metadata
- **Challenge Name:** [e.g., Client XYZ QA Automation Challenge]
- **Target System:** [e.g., PetStore API, Booking System]
- **Type of Testing:** [e.g., E2E, Integration, CRUD, Contract Validation]
- **Level of Effort / Expected Size:** [e.g., Small, Medium, Large]

# Challenge Overview
[Provide a high-level summary of what the challenge asks for. Include the main goals and the big picture of what needs to be verified.]

# API Context
- **Base URL:** [If provided, e.g., `https://api.example.com`. If dynamic, specify "To be passed via environment"]
- **Environment:** [e.g., QA, UAT, Sandbox, "Not specified"]
- **Documentation Link:** [URL to Swagger, Postman collection, or "Not provided"]

# Environment and Configuration Inputs
- **Required Env Variables:** [e.g., `KARATE_ENV`, API Keys]
- **Required System Properties:** [e.g., `-DbaseUrl`, `-Dtoken`]

# Authentication and Authorization
- **Auth Type:** [e.g., Bearer Token, Basic Auth, API Key in Header, OAuth2]
- **Credentials Provided:** [e.g., Yes, No, "Dummy credentials allowed"]
- **Auth Notes:** [e.g., "Token expires every 15 minutes, requires a helper fetching it before tests"]

# Endpoints in Scope
| ID | Method | Endpoint | Purpose | Auth Required | Priority | Notes |
|---|---|---|---|---|---|---|
| REQ-01 | [e.g., GET] | `[e.g., /api/v1/resource]` | [e.g., List resources] | [Yes/No] | [High/Low] | [Any special edge condition] |

# Endpoint Details

## [ID] [Method] [Endpoint]
- **Purpose:** [Brief specific action description]
- **Headers:** [Required headers, e.g., `Accept: application/json`]
- **Path Params:** [Required path variables]
- **Query Params:** [Required query parameters]
- **Request Body:** [Describe the payload schema or reference a payload file]
- **Success Response:** [Expected status code and basic structure]
- **Error Response:** [Expected error codes and structures]
- **Key Assertions:** [Crucial values to assert, e.g., "id must not be null"]
- **Schema Expectations:** [Strict validation or fuzzy match expected?]
- **Data Dependencies:** [e.g., "Requires an existing ID from REQ-02"]
- **Cleanup Impact:** [e.g., "Created resource must be deleted in cleanup phase"]

# Functional Expectations
[Details on the happy paths that must be proven. e.g., "A full CRUD lifecycle starting from creation, reading it, updating its status, and finally deleting it"]

# Negative and Edge Cases
- **Negative Testing:** [e.g., 400 Bad Request if mandatory field is missing, 401 if token is omitted]
- **Edge Cases:** [e.g., Boundary values, concurrent requests, special characters]

# Contract / Schema Validation Expectations
[e.g., "Fuzzy match assertions using `#string`, `#number`, `#notnull` for the main responses"]

# Test Data Strategy
[e.g., "Dynamic data generation using random strings, static data from a CSV, or predefined JSON templates in common/payloads"]

# Scenario Dependencies
[e.g., "The GET scenario depends on the POST scenario running first, or each scenario must create its own data independently (True independence)"]

# Setup Requirements
[e.g., "A user must be created before tests run", or "Auth token must be negotiated in Background using `call read(...)`"]

# Cleanup Requirements
[e.g., "All authored records must be deleted at the end of the test suite (teardown) via `afterScenario` or isolated DELETE steps"]

# Acceptance Criteria
- [ ] [Criterion 1, e.g., "Script successfully creates a resource and asserts 201"]
- [ ] [Criterion 2, e.g., "Negative scenario asserts 404 for nonexistent id"]

# Risks and Constraints
[e.g., "Rate limiting applies, no more than 10 requests per second", or "Sandbox environment is notoriously unstable causing intermittent 502s"]

# Tagging and Execution Notes
- **Tags to apply:** [e.g., `@smoke`, `@regression`, `@challenge`]
- **Execution Command:** [e.g., `mvn test -Dkarate.options="--tags @challenge"`]

# Reporting Expectations
[e.g., "Cucumber HTML report required at `target/karate-reports`"]

# Assumptions
- [e.g., "Assuming the API accepts JSON strictly"]
- [e.g., "Assuming data persistence is reliable between endpoints"]

# Open Questions
- [e.g., "Should we test pagination if the challenge doesn't explicitly mention it?"]
- [e.g., "Is there a specific naming convention expected for the feature files?"]

# Out of Scope
[e.g., "Performance testing is explicitly out of scope for this functional API challenge"]
