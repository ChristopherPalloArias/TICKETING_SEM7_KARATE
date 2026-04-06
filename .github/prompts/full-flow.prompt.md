---
description: 'Orquesta el flujo completo ASDD: Spec → QA → DOC (opcional). Requiere un requerimiento de negocio como input.'
agent: Orchestrator
---

Inicia el flujo completo ASDD.

**Feature**: ${input:featureName:nombre del feature en kebab-case}
**Requerimiento**: ${input:requirement:descripción funcional del feature}

**El @Orchestrator ejecuta automáticamente:**

1. **[FASE 1 — Secuencial]** `Spec Generator` → genera `.github/specs/${input:featureName}.spec.md`
2. **[FASE 2 — Secuencial]** al aprobar la spec:
   - `QA Agent` → estrategia, Gherkin, riesgos, automatización
3. **[FASE 3 — Opcional]** `Documentation Agent` → si el usuario lo solicita

**El requerimiento se puede buscar también en** `.github/requirements/`.
