---
description: Generates a complete Karate feature file using existing assets and ASDD spec artifacts
---

# Skill: Implement Karate Feature

## Purpose
Reads an existing ASDD specification and its related Gherkin/Risks artifacts to generate ONLY the Karate `.feature` file. It works under the assumption that required schemas and payloads have already been created (e.g., via `/implement-karate-assets`).

## Inputs
This skill automatically locates and uses the following files as its source of truth, based on the `<feature>` provided:
- `.github/specs/<feature>.spec.md`
- `.github/specs/<feature>.gherkin.md`
- `.github/specs/<feature>.risks.md`

## Expected Output
It will generate a single, clean `.feature` file:
- `src/test/java/api/<resource>/<resource>-crud.feature` (or an equivalent clean name consistent with the resource)

## Execution Rules
1. **Default Happy Paths**: Start and strictly implement the default happy paths (e.g., GET, POST, PUT, DELETE) based on the specification.
2. **Documented Scenarios Only**: Candidate negative or edge case scenarios from Gherkin or Risks should ONLY be implemented if the spec clearly flags them as documented, stable behavior.
3. **Configuration**: Draw `baseUrl` directly via `karate-config.js` or Karate configuration object (`karate.get('baseUrl')`). DO NOT hardcode base URLs.
4. **Asset Reuse**: Link up and read payloads and schemas generated previously inside `src/test/java/common/payloads/` and `src/test/java/common/schemas/`.
5. **Organization**: Follow standard Karate tagging practices cleanly and consistently. Distinguish tests to skip or specific edge cases contextually.
6. **Maintainability**: Produce an uncluttered, minimalistic, highly professional feature file without excessive comments.
7. **No Speculation**: Discard behaviors you find undocumented. Do not try to write assertions on endpoints that require runtime verification to know their structures, state them clearly.
8. **Exclusions**:
   - DO NOT generate JSON schemas or payloads in this skill.
   - DO NOT touch, mutate, or alter Java runners (like `ChallengeTest.java`) unless absolutely forced to.

## Invocation Parameters
To use the skill, specify the feature name or exact path to the spec:
- `/implement-karate-feature <feature-name>` (e.g. `/implement-karate-feature jsonplaceholder-posts-api-challenge`)
- `/implement-karate-feature .github/specs/<feature>.spec.md`
