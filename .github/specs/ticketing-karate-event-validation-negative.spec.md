---
id: SPEC-007
status: APPROVED
feature: ticketing-karate-event-validation-negative
created: 2026-04-06
updated: 2026-04-06
author: qa-architect
version: "1.0"
related-specs: []
---

# Spec: Ticketing MVP — Karate Event Validation Negative

> Estado: APPROVED

## 1. REQUERIMIENTOS

### Descripción
Automatización Karate para validar los errores de creación de evento cuando los datos no cumplen las reglas básicas de negocio.

### Alcance funcional
Cubre negativos de HU-01:
- aforo superior al máximo
- fecha faltante
- múltiples campos faltantes

### Casos objetivo
- TC-002
- TC-003
- TC-004

### Reglas de negocio
1. No se debe crear evento si capacity supera maxCapacity de sala.
2. No se debe crear evento si falta la fecha.
3. No se debe crear evento con datos obligatorios faltantes.

---

## 2. ESCENARIOS
- Scenario 1: capacity > room maxCapacity
- Scenario 2: missing date
- Scenario 3: missing title and date

---

## 3. TAREAS
- [ ] Crear feature `event-validation-negative.feature`
- [ ] Crear runner `EventValidationNegativeTest.java`
- [ ] Reutilizar room creation del setup
- [ ] Implementar 3 escenarios negativos