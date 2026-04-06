---
id: SPEC-006
status: APPROVED
feature: ticketing-karate-event-availability-visibility
created: 2026-04-06
updated: 2026-04-06
author: qa-architect
version: "1.0"
related-specs: []
---

# Spec: Ticketing MVP — Karate Event Availability Visibility

> Estado: APPROVED

## 1. REQUERIMIENTOS

### Descripción
Automatización Karate para validar la consulta de eventos disponibles y la visualización correcta de disponibilidad por tier.

### Alcance funcional
Cubre HU-03:
- cartelera visible
- tier agotado visible como no disponible
- Early Bird vencido no visible
- evento sin tier activo no muestra opciones de compra

### Casos objetivo
- TC-009
- TC-010
- TC-011
- TC-029

### Reglas de negocio
1. El comprador debe ver eventos publicados con disponibilidad válida.
2. Un tier agotado no debe presentarse como comprable.
3. Early Bird fuera de vigencia no debe mostrarse como opción activa.
4. Si ningún tier está activo, no deben mostrarse opciones de compra.

---

## 2. DISEÑO API

### Endpoints a confirmar en runtime
Usar los endpoints reales de consulta del backend, por ejemplo:
- GET /api/v1/events/...
- GET /api/v1/events/{eventId}/...
- o el endpoint real de seats/availability si corresponde al diseño final

### Estrategia
- setup administrativo para crear evento(s)
- crear tiers con estados variados
- consumir endpoint de visualización real
- validar response visible al comprador

---

## 3. ESCENARIOS

### Scenario 1
Evento visible con disponibilidad por tier

### Scenario 2
Tier agotado

### Scenario 3
Early Bird vencido

### Scenario 4
Evento sin ningún tier activo

---

## 4. TAREAS
- [ ] Auditar endpoint real de disponibilidad/cartelera
- [ ] Crear feature `event-availability-visibility.feature`
- [ ] Crear runner `EventAvailabilityVisibilityTest.java`
- [ ] Implementar 4 escenarios