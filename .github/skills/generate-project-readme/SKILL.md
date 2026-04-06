---
description: Generates or updates the root README.md for the Karate API automation project, applying an elegant, technical, challenge-delivery style based entirely on verified repository evidence with index and collapsible details.
---

# Skill: Generate Project README

## Purpose
The `generate-project-readme` skill generates or updates ONLY the root `README.md` for this Karate API automation repository. Its objective is to produce a highly polished, technical, and elegant deliverable that strictly follows the author's preferred presentation style, integrates clean navigation, and remains 100% evidence-driven.

## Core Rules & Constraints
1. **Target File Only:** Generate or update ONLY the root `README.md`. Do NOT modify `docs/framework/` methodology files, `.github/README.md`, or any test, schema, config, or implementation code.
2. **Strict Evidence Rule:** You must NEVER invent observed API behavior. Only document observed behavior if explicitly backed by:
   - Spec content (`*.spec.md`, `*.gherkin.md`)
   - Repository execution evidence
   - Observed-behavior feature implementation and results
   - Existing evidence already in the repo
   If a status or body behavior isn't proven, omit it or mark it conservatively as "captured during execution" only if truly documented. Do NOT turn undocumented candidate behavior into factual statements.
3. **No Fabrication:** Do not invent CI/CD pipelines, GitHub pages, or unsupported negative-path automation. Let the repo evidence dictate the content.
4. **Format Cleanliness:** Strict markdown rules apply:
   - No stray triple backticks (` ``` `)
   - No broken sections or duplicated headings
   - No dangling code fences or extra blank fences after command blocks
5. **Language & Tone:** English only. Must feel like a polished technical submission without fluffy marketing language.

## Inputs and Information Sources
Read and consolidate information strictly from:
- `.github/requirements/*.md`
- `.github/specs/*.spec.md` (specially the one corresponding to the invoked feature)
- Gherkin/risk artifacts (`*.gherkin.md`, `*.risks.md`)
- `pom.xml`
- `src/test/java/karate-config.js`
- `src/test/java/runners/ChallengeTest.java` (or local runner)
- `src/test/java/api/**/*.feature`
- `src/test/java/common/payloads/**/*.json`
- `src/test/java/common/schemas/**/*.json`
- Existing root `README.md`

## Author Preferences & Style
- **Identity Blocks:** Unless repo evidence defines another author, use these exact defaults:
  - **Author:** Christopher Ismael Pallo Arias
  - **Contact:** 0995312828
  - **Email:** christopherpallo2000@gmail.com
- **Header:** Include a centered header (`<div align="center">`) with strong project title (including emoji), short subtitle, author/contact block, short descriptor, and tech stack icons.
- **Stack Icon Rendering:** Use grouped blocks from `skillicons.dev` (e.g., Automation Stack, Runtime / Build Stack). Use URLs like `https://skillicons.dev/icons?i=java,maven,git,github`. Avoid rendering separate images per technology unless required. Choose the closest icon conservatively.
- **Collapsible Details:** To avoid dumping too much text, use HTML `<details>` and `<summary>` blocks for long lists, grouped scenario explanations, specific run notes, and evidence breakdowns. Top-level summaries (like Coverage) should remain visible as a table, while specific scenario deep-dives sit inside collapsible blocks.

---

## README Structure Required

The generated root `README.md` MUST follow this exact order:

### 1. Centered Header
*(Wrapped in `<div align="center">`)*
- **Project Title:** Strong title with an emoji (e.g., `# 🚀 TITLE`).
- **Subtitle / Context:** Clear subtitle.
- **Author/Contact Block:** The default identity block.
- **Project Descriptor:** Short 1-paragraph description.
- **Grouped Tech Stack Icons:** `skillicons.dev` image links logically grouped.

### 2. Table of Contents
- **Title:** `## 📋 Table of Contents`
- Provide clean anchor links mapping to all major sections in the README. Keep it concise.

### 3. Challenge Context / Overview
- **Title:** `## 🎯 Challenge Context / Overview`
- Explain what this repository is and its purpose as a Karate automation base/challenge template based purely on evidence.

### 4. Environment and Prerequisites (Compatibility)
- **Title:** `## 🛠️ Environment and Prerequisites (Compatibility)`
- Provide a clean markdown table showing Java/JDK version, Maven version if justified, and verification commands. Note any strict compatibility rules.

### 5. Implemented Scope / Coverage
- **Title:** `## 🔍 Implemented Scope / Coverage`
- Display a top-level summary table of implemented happy-path automation.
- **Collapsible Details:** Use `<details><summary>Detailed Scenarios</summary>... </details>` to hide long explanations, scenario groupings, or specific steps.
- Distinguish firmly between implemented assertions and observed behavior capture.

### 6. Project Structure
- **Title:** `## 📂 Project Structure`
- Use a code-block tree representation restricted to meaningful files and folders.

### 7. Configuration Notes
- **Title:** `## ⚙️ Configuration Notes`
- Summarize config behavior: `karate-config.js`, `baseUrl`, runner logic, payload/schema behavior.

### 8. Clone and Setup Instructions
- **Title:** `## ⚡ Clone and Setup Instructions`
- Must be lightweight and realistic (e.g., `git clone` + `cd`). Do not add unrelated setup steps.

### 9. Execution and Report Generation
- **Title:** `## ▶️ Execution and Report Generation`
- Exact Maven commands verified by repo state. Show tag configurations if they exist.
- Specify the standard output location: `target/karate-reports/`.

### 10. Observed API Behavior
- **Title:** `## 📡 Observed API Behavior`
- Summarize the proven API behavior observed during testing (especially mock endpoints, non-persistence traits). 
- **Collapsible Details:** Use `<details>` blocks for verbose behavioral logs, mock body quirks, or specific endpoint behaviors.
- Do NOT turn unverified candidates into facts.

### 11. Evidence / Deliverables
- **Title:** `## 📊 Evidence / Deliverables`
- Include only if artifacts support it (e.g., local HTML reports mentioned in Runner outputs). Use `<details>` if the list is long.

### 12. Limitations / Notes
- **Title:** `## ⚠️ Limitations / Notes`
- Document any proven restrictions, mock caveats, or non-persisted test constraints.

---

## Invocation Parameters
Trigger this skill via the command:
`/generate-project-readme <feature-name>`

*(Example: `/generate-project-readme jsonplaceholder-posts-api-challenge`)*

## Post Actions (Expected Response After Update)
Upon completion of generating the README, output a short summary showing:
1. Exact modified files
2. Whether any additional documents were touched (MUST be NO)
3. A short summary of the newly refined behavior (collapsibles, index, etc.)
4. Any remaining repository limitations or missing evidence discovered.
