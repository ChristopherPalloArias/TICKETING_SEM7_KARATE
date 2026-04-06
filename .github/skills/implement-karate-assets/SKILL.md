---
description: Generates reusable Karate assets (JSON schemas and payloads) from ASDD spec artifacts
---

# Skill: Implement Karate Assets

## Purpose
Reads an existing ASDD specification and its related Gherkin/Risks artifacts to generate ONLY the foundational Karate assets (schemas and payloads). It does not generate `.feature` files or modify existing standard tests.

## Inputs
This skill automatically locates and uses the following files as its source of truth, based on the `<feature>` provided:
- `.github/specs/<feature>.spec.md`
- `.github/specs/<feature>.gherkin.md`
- `.github/specs/<feature>.risks.md`

## Expected Output
It will generate exclusively reusable JSON files aligned with the documented happy paths:
- `src/test/java/common/schemas/<resource>-schema.json`
- `src/test/java/common/payloads/<resource>-create.json`
- `src/test/java/common/payloads/<resource>-update.json`

## Execution Rules
1. **Source of Truth**: Work exclusively from the provided spec, gherkin, and risks.
2. **Configuration**: Assume `baseUrl` and environments are appropriately handled standardly; never hardcode URLs inside payloads or schemas.
3. **Minimalism**: Create only minimal, clean, and highly reusable assets required for the feature.
4. **Valid Schemas**: Generate Karate-compatible fuzzy matchers (e.g., `#string`, `#number`, `#ignore`, `#null`) for schema validations.
5. **No Speculation**: Avoid inventing negative scenarios or data structures that are not explicitly documented in the spec as valid/invalid.
6. **Focus**: Strictly process a single resource as described in the specification, preventing mixups if a spec touches multiple things.
7. **Exclusions**:
   - DO NOT generate `.feature` files.
   - DO NOT modify runner files unless an extreme necessity demands.
   - DO NOT create any other backend/frontend files or non-Karate structures.

## Invocation Parameters
To use the skill, specify the feature name or exact path to the spec:
- `/implement-karate-assets <feature-name>` (e.g. `/implement-karate-assets jsonplaceholder-posts-api-challenge`)
- `/implement-karate-assets .github/specs/<feature>.spec.md`
