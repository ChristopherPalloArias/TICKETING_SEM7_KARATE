---
id: SPEC-003
status: DRAFT
feature: ticketing-karate-expiration-release-flow
created: 2026-04-06
updated: 2026-04-06
author: spec-generator
version: "1.0"
related-specs: ["SPEC-001", "SPEC-002"]
---

# Spec: Ticketing MVP — Karate Expiration and Automatic Release Flow

> **Estado:** `DRAFT` → aprobar con `status: APPROVED` antes de iniciar implementación.
> **Ciclo de vida:** DRAFT → APPROVED → IN_PROGRESS → IMPLEMENTED → DEPRECATED
> **Relacionado con**: SPEC-001 (Approved), SPEC-002 (Rejected)

---

## 1. REQUERIMIENTOS

### Descripción
Automatización Karate del ciclo de vida de expiración y liberación automática de inventario en el MVP de Ticketing. Valida que el sistema libera correctamente la disponibilidad cuando una reservación no se completa exitosamente (por expiración o pago rechazado), previniendo que el inventario permanezca bloqueado. Este feature es crítico para la integridad de negocio del MVP.

### Requerimiento de Negocio
Este feature consiste en implementar una automatización DSL de Karate para validar el ciclo de vida de expiración y liberación automática de inventario en la compra de tickets. La solución debe demostrar que:

1. Cuando una reservación no se completa exitosamente (por timeout o pago rechazado)
2. El mecanismo de fondo automáticamente libera la disponibilidad bloqueada
3. El inventario vuelve a estar disponible para nuevos compradores

Este challenge es crítico para el MVP porque valida una de las reglas de negocio más importantes: prevenir que se bloquee inventario permanentemente cuando un comprador no completa el pago.

**Rutas de negocio soportadas**:
- **Path A**: Expiración sin pago exitoso → liberación automática
- **Path B**: Pago rechazado → liberación automática
- Ambas rutas deben resultar en inventario restaurado y disponible

---

### Historias de Usuario

#### HU-01: Crear Setup de Evento (Reutilizable)

```
Como:        Administrador del sistema
Quiero:      Crear un evento publicado con inventario controlado
Para:        Usar como baseline para validar expiración y liberación

Prioridad:   Alta
Estimación:  S
Dependencias: Ninguna
Capa:        API / Automatización
```

#### Criterios de Aceptación — HU-01

**Happy Path**
```gherkin
CRITERIO-1.1: Crear setup completo (room + event + tier + publish)
  Dado que:    existe un ambiente local/Docker con endpoints disponibles
  Cuando:      ejecutamos setup administrativo
  Entonces:    obtenemos evento PUBLISHED con inventario controlado (cuota: 40, capacidad: 50)
```

---

#### HU-02: Crear Reservación para Validar Bloqueo

```
Como:        Comprador del sistema
Quiero:      Crear una reservación que será expirada o rechazada
Para:        Demostrar que el inventario se bloquea inicialmente

Prioridad:   Alta
Estimación:  S
Dependencias: HU-01
Capa:        API / Automatización
```

#### Criterios de Aceptación — HU-02

**Happy Path**
```gherkin
CRITERIO-2.1: Crear reservación y validar bloqueo inicial
  Dado que:    evento está PUBLISHED con 40 tickets disponibles
  Cuando:      comprador A crea una reservación
  Entonces:    obtenemos reservación en PENDING y disponibilidad baja a 39 (1 bloqueado)
```

---

#### HU-03: Ejercer Path A — Expiración sin Pago

```
Como:        Sistema de Ticketing
Quiero:      Permitir que una reservación expire por timeout sin pago exitoso
Para:        Demostrar que se libera automáticamente la disponibilidad

Prioridad:   Crítica
Estimación:  L
Dependencias: HU-02
Capa:        API / Automatización / Background
```

#### Criterios de Aceptación — HU-03

**Negative Path (Expiration Behavior)**
```gherkin
CRITERIO-3.1: Reservación expira y mecanismo automático la libera
  Dado que:    reservación existe en PENDING con validityWindow expirado
  Cuando:      mecanismo automático procesa expiración
  Entonces:    reservación cambia de estado, disponibilidad es restaurada a 40
```

---

#### HU-04: Ejercer Path B — Pago Rechazado y Liberación

```
Como:        Sistema de Ticketing
Quiero:      Procesar rechazo de pago y liberar automáticamente la disponibilidad
Para:        Demostrar que la liberación ocurre después de fallo de pago

Prioridad:   Crítica
Estimación:  M
Dependencias: HU-02
Capa:        API / Automatización / Background
```

#### Criterios de Aceptación — HU-04

**Negative Path (Payment Rejection + Auto Release)**
```gherkin
CRITERIO-4.1: Pago rechazado, reservación fallida, inventario liberado
  Dado que:    reservación existe en PENDING
  Cuando:      enviamos pago con status DECLINED
  Entonces:    pago rechazado, mecanismo libera automáticamente la reservación
               y disponibilidad es restaurada a 40
```

---

#### HU-05: Validar Restauración de Disponibilidad

```
Como:        Comprador B del sistema
Quiero:      Crear una nueva reservación después que la anterior fue liberada
Para:        Demostrar que el inventario está realmente disponible para nuevos compradores

Prioridad:   Crítica
Estimación:  S
Dependencias: HU-03 o HU-04 (una liberación debe haber ocurrido)
Capa:        API / Automatización
```

#### Criterios de Aceptación — HU-05

**Happy Path (Restoration Verification)**
```gherkin
CRITERIO-5.1: Nuevo comprador puede crear reservación después de liberación
  Dado que:    inventario fue liberado (HU-03 o HU-04)
  Cuando:      comprador B intenta crear reservación
  Entonces:    reservación se crea exitosamente (inventario disponible)
```

---

### Reglas de Negocio (Expiración y Liberación)

1. **Bloqueo Inicial**: Una reservación creada bloquea inmediatamente el inventario (cuota).
2. **Validez Temporal**: La reservación tiene una ventana de validez (`validUntilAt`) después de la cual se puede expirar.
3. **Pago Rechazado = Estado Falló**: Un pago con `status: DECLINED` pone la reservación en estado de fallo.
4. **Liberación Automática**: El mecanismo automático (scheduler/background) libera la reservación fallida/expirada.
5. **Disponibilidad Restaurada**: Cuando se libera, la cuota bloqueada vuelve a estar disponible para nuevos compradores.
6. **No Acumulación de Bloques**: Una vez liberada, la reservación no vuelve a bloquear inventory.

---

## 2. DISEÑO API

### API Endpoints (Setup — Reutilización)

#### POST /api/v1/rooms (HU-01)
- **Descripción**: Crear sala para evento
- **Auth requerida**: Sí (`X-Role: ADMIN`)
- **Request Body**: `{ "name": "string", "maxCapacity": 50 }`
- **Response 201**: Room con id no nulo
- **Notas**: Idéntico a flows aprobado/rechazado

---

#### POST /api/v1/events (HU-01)
- **Descripción**: Crear evento DRAFT
- **Auth requerida**: Sí (`X-Role: ADMIN`)
- **Request Body**:
  ```json
  {
    "roomId": "uuid",
    "title": "string",
    "description": "string",
    "date": "ISO8601 (fecha futura)",
    "capacity": 50,
    "enableSeats": false
  }
  ```
- **Response 201**: Event con status `DRAFT`
- **Notas**: Idéntico a flows previos

---

#### POST /api/v1/events/{eventId}/tiers (HU-01)
- **Descripción**: Configurar tier GENERAL
- **Auth requerida**: Sí (`X-Role: ADMIN`)
- **Request Body**: `[{ "tierType": "GENERAL", "price": 100, "quota": 40 }]`
- **Response 201**: Array de tiers con IDs
- **Notas**: Idéntico, quota: 40 es crítico para validar liberación

---

#### PATCH /api/v1/events/{eventId}/publish (HU-01)
- **Descripción**: Publicar evento
- **Auth requerida**: Sí (`X-Role: ADMIN`)
- **Response 200**: Event con status `PUBLISHED`
- **Notas**: Idéntico a flows previos

---

#### POST /api/v1/reservations (HU-02)
- **Descripción**: Crear reservación (bloquea inventario)
- **Auth requerida**: Sí (`X-User-Id`)
- **Request Body**: `{ "eventId": "uuid", "tierId": "uuid", "buyerEmail": "string" }`
- **Response 201**: Reservation con status `PENDING`, `validUntilAt` poblado
- **Critical**: La reservación bloquea cuota inmediatamente
- **Notas**: Idéntico, pero aquí observamos el bloqueo

---

#### POST /api/v1/reservations/{reservationId}/payments (Optional Path B)
- **Descripción**: Procesar pago rechazado (para Path B)
- **Auth requerida**: Sí (`X-User-Id`)
- **Request Body**: `{ "amount": 100, "paymentMethod": "MOCK", "status": "DECLINED" }`
- **Response**: Rechazo (contrato ya descubierto en SPEC-002)
- **Notas**: Solo para Path B; reutiliza contrato de rejected-payment

---

### Endpoints Críticos para Validación de Liberación

#### GET /api/v1/events/{eventId}/availability (TBD)
- **Descripción**: Obtener disponibilidad actual del evento
- **Auth requerida**: No (o `X-User-Id`)
- **Response**: Información de disponibilidad/cuota actual
- **Critical**: Puede no existir; debe descubrirse en runtime
- **Alternativa**: Validar por SQL a tabla de reservaciones/availability

---

#### GET /api/v1/reservations/{reservationId} (TBD)
- **Descripción**: Obtener estado actual de reservación
- **Auth requerida**: Sí (`X-User-Id`)
- **Response**: Estado de reservación, puede incluir flag de liberación
- **Notas**: Puede usarse para validar transición a estado liberado

---

### Estado de Reservación (Ciclo de Vida)

```
PENDING
  ↓
  ├─→ [Expiración ocurre] → EXPIRED → [Auto-release] → RELEASED
  │
  └─→ [Pago enviado]
       ├─→ APPROVED → CONFIRMED (Path exitoso)
       └─→ DECLINED → FAILED → [Auto-release] → RELEASED
```

---

### Validación de Disponibilidad (Estrategia Mixta)

Debido a que el mecanismo de liberación es asincrónico, se requiere validación en múltiples capas:

1. **HTTP Validation**: Estado de reservación visible via GET
2. **State Validation**: Transición de status observable
3. **Availability Validation**: Cuota/disponibilidad restaurada por HTTP o SQL
4. **SQL Validation** (Last Resort): Validar directamente en base de datos si HTTP insuficiente

---

### Notas de Implementación

> Este feature es significativamente más complejo que approved/rejected flows porque:
>
> 1. **Mecanismo Asincrónico**: La liberación ocurre en background (scheduler), no en respuesta sincrónica
> 2. **Timing**: Requiere esperas controladas (waits) para permitir que mecanismo actúe
> 3. **Disponibilidad de Endpoints**: No hay garantía de endpoint directo para validar disponibilidad
> 4. **SQL Permitido**: Se permite SQL si HTTP/runtime no puede probar liberación
>
> **Estrategia de Implementación**:
> 1. Ejecutar setup y crear reservación
> 2. Esperar que mecanismo actúe (esperar validUntilAt, o procesar pago rechazado)
> 3. Validar cambio de estado por HTTP o SQL
> 4. Validar restauración de disponibilidad por HTTP o SQL
> 5. Validar que comprador nuevo puede reservar (prueba final de liberación)

---

## 3. LISTA DE TAREAS

> Checklist accionable para la automatización en Karate.

### Fase 0: Descubrimiento (Crítico antes de implementación)
- [ ] **Ejecutar contra runtime real**:
  - [ ] ¿Existe endpoint GET /api/v1/events/{eventId}/availability?
  - [ ] ¿Existe endpoint GET /api/v1/reservations/{reservationId}?
  - [ ] ¿Cuál es el mecanismo de expiración? (scheduler, RabbitMQ, otra)
  - [ ] ¿Cuál es el cadence del scheduler? (cada X segundos)
  - [ ] ¿A qué estado transiciona una reservación expirada?
  - [ ] ¿A qué estado transiciona una reservación rechazada?
  - [ ] ¿Se restaura disponibilidad automáticamente?
  - [ ] ¿SQL es necesario para validar estado?

### Fase 1: Implementación Karate (Basada en Descubrimiento)

#### Reutilización de Assets
- [ ] Reutilizar todos los payloads y schemas de flows aprobado/rechazado:
  - `room-create-request.json`
  - `event-create-request.json`
  - `tiers-create-request.json` (CRÍTICO: quota 40)
  - `reservation-create-request.json`
  - `payment-declined-request.json` (si Path B)

#### Nuevos Assets
- [ ] Crear `src/test/java/common/payloads/availability-check-request.json` (si existe endpoint)
- [ ] Crear schema para respuesta de disponibilidad (si existe endpoint)
- [ ] Crear schema para reservación con estado de liberación

#### Feature Karate
- [ ] Crear `src/test/java/api/expiration-release-flow/expiration-release-flow.feature`
  
  **Scenario: Path A — Expiration Without Payment**
  - [ ] HU-01: Setup (room, event, tier, publish)
  - [ ] HU-02: Crear reservación (buyerId: buyer1, observar bloqueo)
  - [ ] Esperar mecanismo de expiración (wait basado en validUntilAt o scheduler cadence)
  - [ ] Validar que reservación cambió de estado (PENDING → EXPIRED o RELEASED)
  - [ ] Validar que disponibilidad fue restaurada
  - [ ] HU-05: Crear segunda reservación (buyerId: buyer2, validar que es posible)
  
  **Scenario: Path B — Rejected Payment + Auto Release**
  - [ ] HU-01: Setup (room, event, tier, publish)
  - [ ] HU-02: Crear reservación (buyerId: buyer1)
  - [ ] HU-04: Procesar pago rechazado
  - [ ] Esperar mecanismo de liberación (wait breve o inmediato)
  - [ ] Validar que reservación cambió de estado (PENDING/FAILED → RELEASED)
  - [ ] Validar que disponibilidad fue restaurada
  - [ ] HU-05: Crear segunda reservación (buyerId: buyer2)

#### Helper Features (SQL si es necesario)
- [ ] Crear `src/test/java/common/sql/check-reservation-state.feature` (si SQL es necesario)
  - Query: `SELECT status FROM reservations WHERE id = ?`
  - Extraer status y comparar contra expected state

#### Test Runner
- [ ] Crear `src/test/java/runners/ExpirationReleaseFlowTest.java`

### Fase 2: Validación y Ajuste de Timing

- [ ] Ejecutar feature localmente
- [ ] Documentar **tiempos reales**:
  - [ ] Tiempo entre crear reservación y liberación (para optimizar waits)
  - [ ] Cadence del scheduler (si es visible)
  - [ ] HTTP endpoint usado para validar estado
- [ ] Ajustar waits en feature basado en observación real
- [ ] Validar que ambos paths funcionan

### Fase 3: Documentación

- [ ] Crear `src/test/java/api/expiration-release-flow/README.md`
  - Explicar ambos paths
  - Documentar waits/timing
  - Notas sobre SQL si fue usado
  - Troubleshooting
- [ ] Actualizar spec con hallazgos de descubrimiento

### Fase 4: Cierre

- [ ] Commit con results de descubrimiento
- [ ] Actualizar estado spec: `status: APPROVED` (cuando esté listo)

---

### Riesgos Identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|---------|-----------|
| Scheduler timing impredecible | ALTA | ALTO | Usar waits conservadores, logging, reintentos |
| No existe endpoint de disponibilidad | MEDIA | ALTO | SQL fallback permitido |
| Mecanismo asincrónico falla silenciosamente | MEDIA | CRITICO | Validar por múltiples métodos (HTTP + SQL) |
| Reservación no se libera correctamente | BAJA | CRITICO | Logging detallado, validación exhaustiva |
| Test es demasiado lento | ALTA | MEDIO | Optimizar waits, considerar mocks si es necesario |

---

### Dependencias Internas

**Path A (Expiration)**:
```
HU-01 (Setup) → HU-02 (Reservation) → [Wait/Scheduler] → HU-03 (Expiración) → HU-05 (Verification)
```

**Path B (Rejected Payment)**:
```
HU-01 (Setup) → HU-02 (Reservation) → HU-04 (Payment Rejected) → [Auto-release] → HU-05 (Verification)
```

Se recomienda implementar ambos paths en la misma feature con `@skip` condicional o en scenarios separados.

---

## 4. MATRIZ DE VALIDACIÓN

### Validación Exhaustiva de Liberación

| Punto de Validación | Método | Prioridad | Notas |
|---|---|---|---|
| Reservación bloqueó inicialmente | HTTP GET /api/v1/reservations/{id} o SQL | ALTA | Observar timestamp de creación |
| Mecanismo ejecutó (expiración/liberación) | Observar cambio de estado en reservación | CRITICA | HTTP o SQL |
| Disponibilidad fue restaurada | HTTP GET /availability o SQL COUNT quota | CRITICA | Preferir HTTP, fallback SQL |
| Nuevo comprador puede reservar | HTTP POST /api/v1/reservations (buyerId diferente) | CRITICA | Prueba final de restauración |
| No hay residuos/bloqueos huérfanos | SQL si necesario | MEDIA | Garantizar limpieza |

---

## Aprobación y Cambios

| Versión | Fecha | Autor | Cambios |
|---------|-------|-------|---------|
| 1.0 | 2026-04-06 | spec-generator | Creación spec inicial DRAFT, reconociendo complejidad asincrónica |

