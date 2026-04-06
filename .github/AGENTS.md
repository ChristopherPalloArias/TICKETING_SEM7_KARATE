# AGENTS.md — ASDD Project

> Canonical shared version: this file is the source of truth for shared agent guidelines.

This file defines general guidance for all AI agents working in this repository, following the **ASDD (Agent Spec Software Development)** workflow.

## Project Summary

> Ver `README.md` en la raíz del proyecto para stack, arquitectura y estructura de carpetas del proyecto actual.
> Ver `.github/README.md` para la estructura completa del framework ASDD.

## ASDD Workflow

**Every new feature must follow this pipeline:**

```
[FASE 1 — Secuencial]
spec-generator    → /generate-spec      → .github/specs/<feature>.spec.md

[FASE 2 — Secuencial]
qa-agent          → /gherkin-case-generator, /risk-identifier

[FASE 3 — Secuencial]
qa-agent          → /implement-karate-assets, /implement-karate-feature

[FASE 4 — Opcional]
documentation-agent → /generate-project-readme → README, API docs, ADRs
```

## Agent Skills (slash commands)

Skills are portable instruction sets invokable as `/command` in Copilot Chat. They work across VS Code, GitHub Copilot CLI, and Copilot coding agent.

### ASDD Core
| Skill | Slash Command | Descripción |
|-------|---------------|-------------|
| asdd-orchestrate | `/asdd-orchestrate` | Orquesta el flujo completo ASDD o consulta estado |
| generate-spec | `/generate-spec` | Genera spec técnica en `.github/specs/` |

### QA
| Skill | Slash Command | Descripción |
|-------|---------------|-------------|
| gherkin-case-generator | `/gherkin-case-generator` | Genera casos Given-When-Then + datos de prueba |
| risk-identifier | `/risk-identifier` | Clasifica riesgos con Regla ASD (Alto/Medio/Bajo) |
| automation-flow-proposer | `/automation-flow-proposer` | Propone flujos a automatizar y framework |
| performance-analyzer | `/performance-analyzer` | Planifica y analiza pruebas de performance |

### Automatización Karate
| Skill | Slash Command | Descripción |
|-------|---------------|-------------|
| implement-karate-assets | `/implement-karate-assets` | Genera assets (schema/payloads) reusables desde la spec |
| implement-karate-feature | `/implement-karate-feature` | Genera el archivo .feature de Karate para la spec |

### Documentación
| Skill | Slash Command | Descripción |
|-------|---------------|-------------|
| generate-project-readme | `/generate-project-readme` | Genera o actualiza el README.md principal basado en implementaciones reales |

## Lineamientos y Contexto

Los agentes deben cargar estos archivos como **primer paso** antes de generar cualquier código:

| Documento | Ruta | Agentes que lo cargan |
|---|---|---|
| Lineamientos de Desarrollo | `.github/docs/lineamientos/dev-guidelines.md` | Todos |
| Lineamientos QA | `.github/docs/lineamientos/qa-guidelines.md` | QA Agent |
| Reglas de Oro | `.github/AGENTS.md` | Todos (siempre activas) |
| Definition of Done | `.github/copilot-instructions.md` | QA Agent, Orchestrator |
| Definition of Ready | `.github/copilot-instructions.md` | Spec Generator, Orchestrator |

---

## Reglas de Oro

> Principio rector: todas las contribuciones de la IA deben ser seguras, transparentes, con propósito definido y alineadas con las instrucciones explícitas del usuario.

### I. Integridad del Código y del Sistema
- **No código no autorizado**: no escribir, generar ni sugerir código nuevo a menos que el usuario lo solicite explícitamente.
- **No modificaciones no autorizadas**: no modificar, refactorizar ni eliminar código, archivos o estructuras existentes sin aprobación explícita del usuario.
- **Preservar la lógica existente**: respetar patrones arquitectónicos, estilo de codificación y lógica operativa del proyecto.

### II. Clarificación de Requisitos
- **Clarificación obligatoria**: si la solicitud es ambigua, incompleta o poco clara, detenerse y solicitar clarificación antes de proceder.
- **No realizar suposiciones**: basar todas las acciones estrictamente en información explícita proporcionada por el usuario.

### III. Transparencia Operativa
- **Explicar antes de actuar**: antes de cualquier acción, explicar qué se va a hacer y posibles implicaciones.
- **Detención ante la incertidumbre**: si surge inseguridad o un conflicto con estas reglas, detenerse y consultar al usuario.
- **Acciones orientadas a un propósito**: cada acción debe ser directamente relevante para la solicitud explícita.

---

## Entradas al Pipeline ASDD

| Tipo | Directorio | Descripción |
|------|-----------|-------------|
| Requerimientos de negocio | `.github/requirements/` | Input: descripción funcional del feature |
| Especificaciones técnicas | `.github/specs/` | Output del Spec Generator, fuente de verdad para implementación |

## Critical Rules for All Agents

1. **No implementation without a spec.** Always check `.github/specs/` first.
2. **Never commit secrets or credentials** — `.env`, credential files and API keys must be in `.gitignore`.

## Development Commands & Integration Notes

> Ver `README.md` en la raíz del proyecto.
