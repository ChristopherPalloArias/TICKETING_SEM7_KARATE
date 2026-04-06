# ASDD — Agent Spec-Driven Development

Framework de desarrollo asistido por IA que transforma requerimientos en código funcional mediante agentes especializados orquestados. Garantiza calidad y trazabilidad a través de especificaciones técnicas aprobadas antes de cualquier implementación.

```
Requerimiento → Spec API → QA → Docs
```

---

## Compatibilidad

| Herramienta | Configuración | Carpeta de agentes |
|-------------|---------------|--------------------|
| **GitHub Copilot** | `.github/copilot-instructions.md` | `.github/agents/` |

---

## Instalación

### GitHub Copilot

1. Instala la extensión **GitHub Copilot Chat** en VS Code
2. Activa el uso de instruction files en tu settings.json de VS Code:

```json
{
  "github.copilot.chat.codeGeneration.useInstructionFiles": true
}
```

3. Copia `.github/` a la raíz de tu proyecto

---

## Flujo de trabajo

### Opción A — Orquestación automática completa

```
/asdd-orchestrate nombre-feature
```

El Orchestrator gestiona todo: genera la spec, espera aprobación, ejecuta fases en paralelo y reporta el estado al final.

### Opción B — Control manual paso a paso

```bash
# 1. Generar especificación técnica
/generate-spec nombre-feature

# 2. Revisar y aprobar la spec generada en .github/specs/<feature>.spec.md
#    Cambiar el campo:  status: DRAFT  →  status: APPROVED

# 3. Análisis QA y Generación de Gherkin
/gherkin-case-generator
/risk-identifier
```

> **Regla de Oro**: Ningún agente escribe código si la spec no tiene `status: APPROVED`.

---

## Skills disponibles

| Comando | Qué hace |
|---------|----------|
| `/asdd-orchestrate` | Orquesta el flujo ASDD completo |
| `/generate-spec` | Genera spec técnica en `.github/specs/` |
| `/gherkin-case-generator` | Genera escenarios Given-When-Then y datos de prueba |
| `/risk-identifier` | Clasifica riesgos de calidad (Alto / Medio / Bajo) |
| `/automation-flow-proposer` | Propone flujos a automatizar con análisis de ROI |
| `/performance-analyzer` | Define estrategia de performance testing |

---

## Agentes disponibles

| Agente | Fase | Responsabilidad |
|--------|------|-----------------|
| `orchestrator` | Entry point | Coordina el flujo completo |
| `spec-generator` | 1 | Genera especificaciones técnicas |
| `qa-agent` | 2 | Estrategia QA, Gherkin, riesgos, performance |
| `documentation-agent` | 3 | README, API docs, ADRs |

**GitHub Copilot**: usa `@nombre-agente` en el chat o los prompts en `.github/prompts/`

---

## Ciclo de vida de una spec

```
DRAFT → APPROVED → IN_PROGRESS → IMPLEMENTED → DEPRECATED
```

Las specs viven en `.github/specs/<feature>.spec.md`. Solo pasan a implementación cuando el usuario las aprueba manualmente cambiando el campo `status`.

---

## Estructura del repositorio

```
.
├── .github/                        ← Configuración GitHub Copilot
│   ├── copilot-instructions.md     ← Instrucciones globales + diccionario de dominio
│   ├── AGENTS.md                   ← Reglas de Oro para todos los agentes
│   ├── agents/                     ← Agentes Copilot
│   ├── skills/                     ← Skills portables
│   ├── instructions/               ← Instrucciones por scope (backend, frontend, tests)
│   ├── prompts/                    ← Prompts rápidos reutilizables
│   ├── requirements/               ← Requerimientos de entrada (input)
│   └── specs/                      ← Especificaciones técnicas (output de fase 1)
```

---

## Ejemplo completo

```bash
# 1. Escribe el requerimiento
echo "El usuario debe poder convertir monedas en tiempo real" \
  > .github/requirements/conversiones.md

# 2. Genera la spec
/generate-spec conversiones

# 3. Abre .github/specs/conversiones.spec.md, revisa y cambia:
#    status: DRAFT  →  status: APPROVED

# 4. Orquesta la evaluación
/asdd-orchestrate conversiones

# → Spec generada
# → QA Gherkin completado
```

---

## Documentación interna

- `.github/README.md` — Guía detallada para GitHub Copilot
- `.github/AGENTS.md` — Reglas de Oro y lineamientos de todos los agentes
- `.github/specs/README.md` — Convenciones y ciclo de vida de specs
