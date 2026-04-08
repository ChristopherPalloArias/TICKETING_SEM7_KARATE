# ASDD — Agent Spec-Driven Development

**ASDD** (Agent Spec Software Development) es un framework de desarrollo asistido por IA que organiza el trabajo de software en diversas fases orquestadas por agentes especializados.

```text
Requerimiento → Spec API → QA → Implementación → Doc (opcional)
```

> Esta guía cubre el uso con **GitHub Copilot Chat** en VS Code.

---

## Requisitos

| Requisito | Detalle |
|---|---|
| VS Code | Cualquier versión reciente |
| GitHub Copilot Chat | Extensión instalada y activa |
| Setting habilitado | `github.copilot.chat.codeGeneration.useInstructionFiles: true` |

El archivo `.vscode/settings.json` ya configura el auto-descubrimiento de agentes, skills e instructions. Si no existe, créalo con las rutas correspondientes a `.github/`.

---

## Onboarding — nuevo proyecto

Al copiar `.github/` y `docs/` a un proyecto nuevo, completa estos archivos **en orden** antes de usar cualquier agente:

| # | Archivo | Qué escribir |
|---|---------|-------------|
| 1 | `README.md` (raíz del proyecto) | Stack de automatización Karate y diseño API |
| 2 | `copilot-instructions.md` | Términos canónicos del negocio (glosario) |
| 3 | `copilot-instructions.md` | Criterios DoR y DoD del equipo |

Una vez completados, los agentes tienen todo el contexto para operar de forma autónoma.

**No modificar**: `agents/`, `skills/`, `instructions/`, `.github/docs/lineamientos/`, `copilot-instructions.md`, `AGENTS.md`

---

## El flujo ASDD paso a paso

### Paso 1 — Spec (obligatorio, siempre primero)

Genera la especificación técnica antes de escribir código:

```
@Spec Generator genera la spec para: [tu requerimiento]
```
```
/generate-spec <nombre-feature>
```

El agente valida el requerimiento y genera `specs/<feature>.spec.md` con estado `DRAFT`.
Revisa y aprueba la spec (cambia a `APPROVED`) antes de continuar.

---

### Paso 2 — QA

Con la spec `APPROVED`, ejecuta la estrategia QA:

```
@QA Agent ejecuta QA para specs/<feature>.spec.md
```

El agente genera: casos Gherkin y matriz de riesgos.

---

### Paso 3 — Implementation (Karate)

With the QA strategy ready from the previous phase:

```text
@Implement Karate Assets Agent builds schemas and payloads layer for specs/<feature>.spec.md
@Implement Karate Feature Agent assembles the final .feature for specs/<feature>.spec.md
```

Both agents enforce structured automation implementation for Karate.

---

### Paso 4 — Documentación *(opcional)*

Al cerrar el feature:

```
@Documentation Agent documenta el feature specs/<feature>.spec.md
```

---

### Flujo completo con Orchestrator

```
@Orchestrator ejecuta el flujo completo para: [tu requerimiento]
```
```
/asdd-orchestrate <nombre-feature>
```

## Agentes disponibles (`@name` in Copilot Chat)

| Agent | Phase | When to use |
|---|---|---|
| `@Orchestrator` | Entry point | Coordinate the full flow (`/asdd-orchestrate status` to see status) |
| `@Spec Generator` | Phase 1 | Validate a requirement and generate its technical spec |
| `@QA Agent` | Phase 2 | Gherkin, risks, and BDD analysis |
| `@Implement Karate Assets Agent`| Phase 3 | Generate reusable schemas and payloads for Karate |
| `@Implement Karate Feature Agent`| Phase 3 | Generate .feature file by assembling previous assets |
| `@Documentation Agent` | Phase 4 | README, API docs, and ADRs |

---

## Skills disponibles (`/command` in Copilot Chat)

| Command | Agent | What it does |
|---|---|---|
| `/asdd-orchestrate` | Orchestrator | Orchestrates the full flow or shows current status |
| `/generate-spec` | Spec Generator | Generates technical spec with INVEST/IEEE 830 validation |
| `/gherkin-case-generator` | QA Agent | Critical flows + Given-When-Then cases + test data |
| `/risk-identifier` | QA Agent | ASD risk matrix (High/Medium/Low) |
| `/performance-analyzer` | QA Agent | Performance test planning |
| `/generate-project-readme` | Documentation Agent | Generates or updates the main Karate framework README.md |
| `/implement-karate-assets` | Implement Karate Assets Agent | Generates reusable Karate assets (schemas and payloads) |
| `/implement-karate-feature` | Implement Karate Feature Agent | Generates the complete Karate .feature file |

---

## Prompts disponibles (`/name` in Copilot Chat)

Alternativa rápida a invocar agentes directamente:

| Comando | Cuándo usarlo |
|---|---|
| `/generate-spec` | Crear una nueva spec desde un requerimiento |
| `/qa-task` | Ejecutar el flujo QA (Gherkin + riesgos) |
| `/doc-task` | Generar documentación técnica del feature |
| `/full-flow` | Orquestar todas las fases de principio a fin |

---

## Instructions automáticas (sin intervención manual)

Inyectadas automáticamente por Copilot cuando el archivo activo coincide:

| Archivo activo | Instructions aplicadas |
|---|---|
| `**/*.feature` | `instructions/tests.instructions.md` |

> Si el proyecto usa otro stack, ajusta los patrones `applyTo:` de cada archivo.

---

## Instructions automáticas (sin intervención manual)

Inyectadas automáticamente por Copilot cuando el archivo activo coincide:

| Archivo activo | Instructions aplicadas |
|---|---|
| `src/test/java/**/*.feature` | `instructions/karate.instructions.md` |
| `src/test/java/**/*.java` | `instructions/karate.instructions.md` |

> Si el framework asume una convención de nombramiento diferente, ajusta los patrones `applyTo:` de cada archivo de `.github/instructions`.

---

## Lineamientos de referencia

Cargados automáticamente por los agentes:

| Documento | Contenido |
|---|---|
| `.github/docs/lineamientos/dev-guidelines.md` | Clean Code, SOLID, API REST, Seguridad, Observabilidad |
| `.github/docs/lineamientos/qa-guidelines.md` | Estrategia QA, Gherkin, Riesgos, Automatización, Performance |
| `.github/docs/lineamientos/guidelines.md` | Referencia rápida de estándares: código, tests, API, Git |

---

## Estructura de carpetas

```
Project Root/
│
├── docs/output/                     ← artefactos generados por los agentes
│   ├── qa/                          ← Gherkin, riesgos, performance
│   ├── api/                         ← documentación de API
│   └── adr/                         ← Architecture Decision Records
│
└── .github/                         ← framework Copilot (auto-contenido para compartir)
    ├── README.md                    ← este archivo
    ├── AGENTS.md                    ← reglas críticas para todos los agentes
    ├── copilot-instructions.md      ← siempre activo en Copilot Chat
    │
    ├── agents/                      ← agentes (@nombre en Copilot Chat)
    │   ├── orchestrator.agent.md
    │   ├── spec-generator.agent.md
    │   ├── qa.agent.md
    │   ├── implement-karate-assets.agent.md
    │   ├── implement-karate-feature.agent.md
    │   └── documentation.agent.md
    │
    ├── skills/                      ← skills (/comando en Copilot Chat)
    │   ├── asdd-orchestrate/
    │   ├── generate-spec/
    │   ├── gherkin-case-generator/
    │   ├── risk-identifier/
    │   ├── automation-flow-proposer/
    │   ├── implement-karate-assets/
    │   ├── implement-karate-feature/
    │
    ├── docs/lineamientos/           ← guidelines del framework (incluidos al compartir)
    │   ├── dev-guidelines.md
    │   └── qa-guidelines.md
    │
    ├── prompts/                     ← 8 prompts (/nombre en Copilot Chat)
    │
    ├── instructions/                ← aplicadas automáticamente por contexto de archivo
    │
    ├── requirements/                ← requerimientos de negocio (input del pipeline)
    │   └── <feature>.md
    │
    └── specs/                       ← specs técnicas (fuente de verdad)
        └── <feature>.spec.md        ← DRAFT → APPROVED → IN_PROGRESS → IMPLEMENTED
```

---

## Reglas de Oro

1. **No código sin spec aprobada** — siempre debe existir `specs/<feature>.spec.md` con estado `APPROVED`.
2. **No código no autorizado** — los agentes no generan ni modifican código sin instrucción explícita.
3. **No suposiciones** — si el requerimiento es ambiguo, el agente pregunta antes de actuar.
4. **Transparencia** — el agente explica qué va a hacer antes de hacerlo.
