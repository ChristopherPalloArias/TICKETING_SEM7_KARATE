# Copilot Instructions

## ASDD Workflow (Agent Spec Software Development)

Este repositorio sigue el flujo **ASDD**: toda funcionalidad nueva se ejecuta en cuatro fases orquestadas por agentes especializados.

```
[Orchestrator] → [Spec Generator] → [QA] → [Implement] → [Doc]
```

### Fases del flujo ASDD
1. **Spec**: El agente `spec-generator` genera la spec en `.github/specs/<feature>.spec.md`.
2. **QA**: `qa-agent` genera estrategia, Gherkin, riesgos y automatización.
3. **Implement**: `implement-karate-assets` e `implement-karate-feature` generan esquema base y features para Karate.
4. **Doc (opcional)**: `documentation-agent` genera README updates, API docs y ADRs.

### Skills disponibles (slash commands):
- `/asdd-orchestrate` — orquesta el flujo completo ASDD o consulta estado
- `/generate-spec` — genera spec técnica en `.github/specs/`
- `/gherkin-case-generator` — casos Given-When-Then + datos de prueba
- `/risk-identifier` — clasificación de riesgos ASD (Alto/Medio/Bajo)
- `/automation-flow-proposer` — propuesta de automatización con ROI
- `/performance-analyzer` — planificación de pruebas de performance
- `/generate-project-readme` — genera o actualiza el README.md principal del framework Karate basado en la implementación
- `/implement-karate-assets` — genera assets base reutilizables (schemas y payloads)
- `/implement-karate-feature` — genera la automatización final de Karate (.feature)

### Requerimientos y Specs
- Los requerimientos de negocio viven en `.github/requirements/`. Son la entrada al pipeline ASDD.
- Las specs técnicas viven en `.github/specs/`. Cada spec es la fuente de verdad para implementar.
- Antes de implementar cualquier desarrollo, debe existir una spec aprobada en `.github/specs/`.
- Flujo: `requirements/<feature>.md` → `/generate-spec` → `specs/<feature>.spec.md` (APPROVED)

---

## Mapa de Archivos ASDD

### Agentes
| Agente | Fase | Ruta |
|---|---|---|
| Orchestrator | Entry point | `.github/agents/orchestrator.agent.md` |
| Spec Generator | Fase 1 | `.github/agents/spec-generator.agent.md` |
| QA Agent | Fase 2 | `.github/agents/qa.agent.md` |
| Implement Karate Assets Agent | Fase 3 | `.github/agents/implement-karate-assets.agent.md` |
| Implement Karate Feature Agent | Fase 3 | `.github/agents/implement-karate-feature.agent.md` |
| Documentation Agent | Fase 4 | `.github/agents/documentation.agent.md` |

### Skills
| Skill | Agente | Ruta |
|---|---|---|
| `/asdd-orchestrate` | Orchestrator | `.github/skills/asdd-orchestrate/SKILL.md` |
| `/generate-spec` | Spec Generator | `.github/skills/generate-spec/SKILL.md` |
| `/gherkin-case-generator` | QA Agent | `.github/skills/gherkin-case-generator/SKILL.md` |
| `/risk-identifier` | QA Agent | `.github/skills/risk-identifier/SKILL.md` |
| `/automation-flow-proposer` | QA Agent | `.github/skills/automation-flow-proposer/SKILL.md` |
| `/performance-analyzer` | QA Agent | `.github/skills/performance-analyzer/SKILL.md` |
| `/generate-project-readme` | Documentation Agent | `.github/skills/generate-project-readme/SKILL.md` |
| `/implement-karate-assets` | Implement Karate Assets Agent | `.github/skills/implement-karate-assets/SKILL.md` |
| `/implement-karate-feature` | Implement Karate Feature Agent | `.github/skills/implement-karate-feature/SKILL.md` |

### Instructions (path-scoped)
| Scope | Ruta | Se aplica a |
|---|---|---|
| Karate Automation | `.github/instructions/karate.instructions.md` | `src/test/java/**/*.feature` · `src/test/java/**/*.java` |

### Lineamientos y Contexto
| Documento | Ruta |
|---|---|
| Lineamientos de Desarrollo | `.github/docs/lineamientos/dev-guidelines.md` |
| Lineamientos QA | `.github/docs/lineamientos/qa-guidelines.md` |

### Lineamientos generales para todos los agentes
- **Reglas de Oro**: ver `.github/AGENTS.md` — rigen TODAS las interacciones.
- **Specs activas**: `.github/specs/` — consultar siempre antes de implementar.

---

## Reglas de Oro

> Principio rector: todas las contribuciones de la IA deben ser seguras, transparentes, con propósito definido y alineadas con las instrucciones explícitas del usuario.

### I. Integridad del Código y del Sistema
- **No código no autorizado**: no escribir, generar ni sugerir código nuevo a menos que el usuario lo solicite explícitamente.
- **No modificaciones no autorizadas**: no modificar, refactorizar ni eliminar código, archivos o estructuras existentes sin aprobación explícita.
- **Preservar la lógica existente**: respetar los patrones arquitectónicos, el estilo de codificación y la lógica operativa existentes del proyecto.

### II. Clarificación de Requisitos
- **Clarificación obligatoria**: si la solicitud es ambigua, incompleta o poco clara, detenerse y solicitar clarificación antes de proceder.
- **No realizar suposiciones**: basar todas las acciones estrictamente en información explícita provista por el usuario.

### III. Transparencia Operativa
- **Explicar antes de actuar**: antes de cualquier acción, explicar qué se hará y posibles implicaciones.
- **Detención ante la incertidumbre**: si surge inseguridad o conflicto con estas reglas, detenerse y consultar al usuario.
- **Acciones orientadas a un propósito**: cada acción debe ser directamente relevante para la solicitud explícita.

---

## Diccionario de Dominio

Términos canónicos a usar en specs, código y mensajes:

| Término | Definición | Sinónimos rechazados |
|---------|-----------|---------------------|
| **Usuario** (`user`) | Persona autenticada mediante Firebase | Persona, cliente |
| **Perfil** (`profile`) | Datos personales y configuración del Usuario | Cuenta, ficha |
| **UID** (`uid`) | Identificador único provisto por Firebase Auth | ID técnico, `_id` |
| **Pregunta Frecuente** (`faq`) | Par pregunta-respuesta publicado para consulta | Artículo de ayuda |
| **Pregunta** (`question`) | Texto de la pregunta dentro de una FAQ | Título |
| **Respuesta** (`answer`) | Texto de la respuesta dentro de una FAQ | Descripción, contenido |
| **Dashboard** | Pantalla principal con métricas (solo lectura) | Inicio |
| **Modo Oscuro** (`dark mode`) | Tema visual alternativo con colores oscuros | Modo noche |
| **Token** (`idToken`) | Token Firebase en header `Authorization: Bearer` | Contraseña, sesión |
| **Administrador** | Rol con permisos completos | Superusuario |
| `created_at` | Timestamp de creación en UTC | Fecha alta |
| `updated_at` | Timestamp de última actualización en UTC | Fecha modificación |

**Reglas:** `uid` siempre de Firebase. `FAQ` = par completo. Timestamps en snake_case. `Dashboard` es solo lectura.

---

## Project Overview

> Ver `README.md` en la raíz del proyecto.
