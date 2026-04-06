---
name: asdd-orchestrate
description: Orquesta el flujo ASDD completo. Fase 1 (Spec) → Fase 2 (QA).
argument-hint: "<nombre-feature> | status"
---

# ASDD Orchestrate

## Flujo

```
[FASE 1 — SECUENCIAL]
  spec-generator → .github/specs/<feature>.spec.md  (DRAFT → APPROVED)

[FASE 2 — SECUENCIAL]
  qa-agent → /gherkin-case-generator, /risk-identifier
```

## Proceso
1. Busca `.github/specs/<feature>.spec.md`
   - No existe → ejecuta `/generate-spec` y espera
   - `DRAFT` → pide aprobación al usuario
   - `APPROVED` → actualiza a `IN_PROGRESS` y continúa
2. Lanza Fase 2 (qa-agent)
3. Actualiza spec a `IMPLEMENTED` y reporta estado final

## Comando status
Al recibir `status`: lista specs en `.github/specs/` con su estado y próxima acción pendiente.

## Reglas
- Sin spec `APPROVED` → no hay validación — sin excepciones
- Si una fase falla → detener el flujo y notificar al usuario con contexto
- Fase 3 (doc) solo si el usuario la solicita explícitamente
