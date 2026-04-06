---
id: SPEC-009
status: APPROVED
feature: ticketing-karate-reservation-advanced-lifecycle
created: 2026-04-06
updated: 2026-04-06
author: qa-architect
version: "1.0"
related-specs: ["SPEC-001", "SPEC-002", "SPEC-003"]
---

# Spec: Ticketing MVP — Karate Reservation Advanced Lifecycle

> Estado: APPROVED

## 1. REQUERIMIENTOS

### Descripción
Automatización Karate para validar escenarios avanzados del ciclo de vida de una reservación, incluyendo expiración pura, intento de pago sobre reservación expirada, concurrencia y reglas adicionales del scheduler.

### Alcance funcional
Cubre:
- expiración pura sin pago
- pago sobre reservación ya expirada
- concurrencia sobre última disponibilidad
- compra confirmada no debe ser liberada
- regularización/job de respaldo si existe

### Casos objetivo
- TC-014
- TC-015
- TC-016
- TC-018
- TC-019
- TC-026
- TC-028

### Reglas de negocio
1. Una reservación vencida no debe poder pagarse exitosamente.
2. El scheduler no debe liberar compras confirmadas.
3. La concurrencia no debe generar sobreventa.
4. La expiración pura también debe restaurar disponibilidad.
5. Si existe job de respaldo, debe procesar reservas pendientes no liberadas.

---

## 2. ESCENARIOS
- Scenario 1: pure expiration without payment
- Scenario 2: payment attempt on expired reservation
- Scenario 3: concurrency on last slot
- Scenario 4: confirmed purchase must not be released
- Scenario 5: backup job / fallback mechanism if runtime supports it

---

## 3. TAREAS
- [ ] Crear feature `reservation-advanced-lifecycle.feature`
- [ ] Crear runner `ReservationAdvancedLifecycleTest.java`
- [ ] Usar SQL cuando el runtime asincrónico lo requiera
- [ ] No inventar jobs/endpoints si no existen