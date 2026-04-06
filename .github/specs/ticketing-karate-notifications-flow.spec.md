---
id: SPEC-005
status: APPROVED
feature: ticketing-karate-notifications-flow
created: 2026-04-06
updated: 2026-04-06
author: qa-architect
version: "1.0"
related-specs: ["SPEC-001", "SPEC-002", "SPEC-003"]
---

# Spec: Ticketing MVP — Karate Notifications Flow

> Estado: APPROVED

## 1. REQUERIMIENTOS

### Descripción
Automatización Karate para validar que el sistema genera notificaciones correctas al comprador tras compra aprobada, pago rechazado y liberación por expiración.

### Alcance funcional
Cubre HU-06:
- notificación por compra exitosa
- notificación por pago fallido
- notificación por liberación por expiración

### Casos objetivo
- TC-020
- TC-021
- TC-022

### Reglas de negocio
1. Una compra confirmada debe generar notificación al comprador.
2. Un pago rechazado debe generar notificación de fallo.
3. Una reserva liberada por expiración debe generar notificación de liberación.
4. La validación puede ser por endpoint o por SQL, según runtime real.

---

## 2. DISEÑO TÉCNICO

### Fuente de validación preferida
1. Endpoint de notificaciones si existe y es usable
2. SQL en `db-notifications` si el endpoint no es suficiente

### Endpoint posible
#### GET /api/v1/notifications/buyer/{id}
- Si existe, usarlo para validar presencia y tipo de notificación

### Validación SQL permitida
Se permite consultar la tabla de notificaciones para:
- buyer_id
- type/status/message
- created_at

---

## 3. ESTRATEGIA

### Scenario 1
Approved purchase:
- setup
- approved payment
- validar notificación exitosa

### Scenario 2
Rejected payment:
- setup
- declined payment
- validar notificación de pago fallido

### Scenario 3
Expiration / release:
- setup
- create reservation
- forzar expiración si hace falta
- esperar mecanismo
- validar notificación de liberación

---

## 4. CRITERIOS DE ACEPTACIÓN

- [ ] Existe evidencia de notificación para compra aprobada
- [ ] Existe evidencia de notificación para pago rechazado
- [ ] Existe evidencia de notificación para expiración/liberación

---

## 5. TAREAS

- [ ] Auditar si endpoint de notificaciones es usable
- [ ] Si no, usar SQL
- [ ] Crear feature `notifications-flow.feature`
- [ ] Crear runner `NotificationsFlowTest.java`
- [ ] Reutilizar flows approved / rejected / expiration