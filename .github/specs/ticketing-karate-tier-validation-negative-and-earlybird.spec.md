---
id: SPEC-008
status: APPROVED
feature: ticketing-karate-tier-validation-negative-and-earlybird
created: 2026-04-06
updated: 2026-04-06
author: qa-architect
version: "1.0"
related-specs: []
---

# Spec: Ticketing MVP — Karate Tier Validation Negative and Early Bird

> Estado: APPROVED

## 1. REQUERIMIENTOS

### Descripción
Automatización Karate para validar errores en la configuración de tiers y la vigencia del Early Bird.

### Alcance funcional
Cubre:
- Early Bird dentro/fuera de ventana
- precios inválidos
- suma de cupos mayor al aforo

### Casos objetivo
- TC-006
- TC-007
- TC-008

### Reglas de negocio
1. Early Bird solo debe estar disponible dentro de su ventana.
2. No se deben aceptar precios 0 o negativos.
3. La suma de quotas no debe superar capacity del evento.

---

## 2. ESCENARIOS
- Scenario 1: Early Bird visible dentro de ventana y no visible fuera
- Scenario 2: rechazo de precio inválido
- Scenario 3: rechazo de quota que excede aforo

---

## 3. TAREAS
- [ ] Crear feature `tier-validation-negative-and-earlybird.feature`
- [ ] Crear runner `TierValidationNegativeAndEarlyBirdTest.java`
- [ ] Implementar 3 escenarios