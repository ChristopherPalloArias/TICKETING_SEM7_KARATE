# Karate Automation Instructions

This scope configures how you interact with the Karate framework under `src/test/java`.

## Core Principles
1. **API-First & QA-Centric**: All Karate scripts derive from the ASDD Spec (`.github/specs/`) and QA phase. Do not invent behaviors that are not documented in the spec.
2. **Minimalism**: Keep `.feature` files clean, strictly structured according to Arrange-Act-Assert (`Given`, `When`, `Then`), and use precise Gherkin verbal descriptions.
3. **No Hardcoding**: Never hardcode URLs or credentials. Always use variables defined in `karate-config.js` or `karate.env`. Delegate auth to generic helpers in `common/auth/`.
4. **Robust Assertions**: Ensure you include `match response == ...` against schema templates or specific expected values.
5. **English-Only**: Do not use emojis anywhere, keep feature names and scenarios in strictly professional English.

## Expected Structure
```text
src/test/java/
└── api/                       (Main execution entry scopes)
    └── [feature-name]/        (Bounded Context per feature)
        └── [feature].feature
└── common/
    ├── auth/                  (Token negotiation logic)
    ├── payloads/              (Re-usable request *.json files)
    ├── schemas/               (Re-usable expected *.json files)
    └── utils/                 (Helper Java files if custom code is needed)
```
When implementing a scenario, isolate payload assets and expected schemas in `common/payloads` or `common/schemas` to avoid excessively long `.feature` files.
