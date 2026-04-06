---
id: SPEC-004
status: APPROVED
feature: ticketing-karate-ticket-visibility-and-access-control
created: 2026-04-06
updated: 2026-04-06
author: qa-architect
version: "1.0"
related-specs: ["SPEC-001", "SPEC-002"]
---

# Spec: Ticketing MVP — Karate Ticket Visibility and Access Control

> **Estado:** `APPROVED`
> **Ciclo de vida:** DRAFT → APPROVED → IN_PROGRESS → IMPLEMENTED → DEPRECATED

---

## 1. REQUERIMIENTOS

### Descripción

Automatización Karate para validar la visualización del ticket confirmado tras una compra exitosa, la consistencia de sus datos, la ausencia de ticket para operaciones no confirmadas, y la restricción de acceso al ticket por propietario.

### Requerimiento de Negocio

Este challenge consiste en implementar una automatización Karate que valide visibilidad y control de acceso a tickets en el MVP de Ticketing. La solución debe:

1. Demostrar que un ticket es visible y contiene datos correctos tras compra aprobada
2. Validar que compra rechazada NO genera ticket exitoso
3. Garantizar que comprador no accede a ticket de otro comprador
4. Verificar consistencia entre reservación, pago y ticket

---

### Historias de Usuario

#### HU-07: Visualizar Ticket Confirmado (Happy Path)

```text
Como:        Comprador del sistema
Quiero:      Visualizar el ticket otorgado tras compra exitosa
Para:        Confirmar que mi compra fue procesada correctamente

Prioridad:   Alta
Estimación:  M
Dependencias: HU-06 (Payment APPROVED)
Capa:        API / Automatización
```

#### Criterios de Aceptación — HU-07

**Happy Path**

```gherkin
CRITERIO-7.1: Ticket visible para propietario tras compra aprobada
  Dado que:    completé una compra exitosa con pago APPROVED
  Cuando:      solicito GET /api/v1/tickets/{ticketId} con X-User-Id coincidente
  Entonces:    recibo respuesta 200 con ticket incluyendo eventId, tier, pricePaid y buyerEmail
```

```gherkin
CRITERIO-7.2: Ticket contiene información consistente
  Dado que:    la respuesta de pago incluyó ticketId
  Cuando:      consulto GET /api/v1/tickets/{ticketId}
  Entonces:    evento, tier y precio pagado coinciden con reservación y pago registrados
```

---

#### HU-08: Validar Ausencia de Ticket en Compra Rechazada

```text
Como:        Operador del sistema
Quiero:      Garantizar que compra rechazada NO genera ticket
Para:        Evitar entradas huérfanas y mantener integridad transaccional

Prioridad:   Alta
Estimación:  S
Dependencias: HU-06 (Payment DECLINED)
Capa:        API / Automatización
```

#### Criterios de Aceptación — HU-08

**Negative Path**

```gherkin
CRITERIO-8.1: No hay ticket exitoso en respuesta de pago rechazado
  Dado que:    la respuesta HTTP de pago es 400 (DECLINED)
  Cuando:      valido la respuesta
  Entonces:    no existe campo ticketId exitoso, o está nulo o vacío
```

```gherkin
CRITERIO-8.2: Ausencia de ticket en consulta GET
  Dado que:    intento consultar GET /api/v1/tickets/{ticketId} con ticketId nulo o inexistente
  Cuando:      envío la solicitud
  Entonces:    recibo respuesta que indica ausencia o error (4xx)
```

---

#### HU-09: Restricción de Acceso al Ticket por Propietario

```text
Como:        Sistema de seguridad
Quiero:      Prevenir que comprador acceda a tickets ajenos
Para:        Garantizar privacidad y aislamiento entre usuarios

Prioridad:   Crítica
Estimación:  M
Dependencias: HU-07 (Ticket visible)
Capa:        API / Automatización
```

#### Criterios de Aceptación — HU-09

**Access Control Path**

```gherkin
CRITERIO-9.1: Comprador B no accede a ticket de Comprador A
  Dado que:    Comprador A posee ticket válido tras compra exitosa
  Cuando:      Comprador B intenta GET /api/v1/tickets/{ticketIdA} con su X-User-Id
  Entonces:    recibo respuesta 403 Forbidden o rechazo equivalente del runtime
```

```gherkin
CRITERIO-9.2: X-User-Id debe coincidir con propietario del ticket
  Dado que:    ticket fue generado por reservación de Comprador A
  Cuando:      intento consultarlo con X-User-Id diferente
  Entonces:    acceso es rechazado independientemente de ticketId válido
```

---

## 2. DISEÑO

### Setup Reutilizado

Se reutiliza el setup ya validado en SPEC-001:

* `POST /api/v1/rooms`
* `POST /api/v1/events`
* `POST /api/v1/events/{eventId}/tiers`
* `PATCH /api/v1/events/{eventId}/publish`
* `POST /api/v1/reservations`
* `POST /api/v1/reservations/{reservationId}/payments` (APPROVED o DECLINED)

---

#### GET /api/v1/tickets/{ticketId}

* **Descripción**: Recupera detalles de ticket confirmado
* **Auth requerida**: Sí (`X-User-Id`)
* **Path Params**: `ticketId` (uuid)
* **Request Body**: Vacío
* **Response esperada (200 OK)**:

  ```json
  {
    "ticketId": "#uuid",
    "eventId": "#uuid",
    "eventTitle": "#string",
    "eventDate": "#string",
    "tier": "#string",
    "pricePaid": "#number",
    "status": "#string",
    "buyerEmail": "#string",
    "reservationId": "#uuid",
    "purchasedAt": "#string"
  }
  ```

* **Response esperada (403 Forbidden)**:

  En caso de acceso cruzado (X-User-Id no coincide con propietario) o ticket inexistente

---

### Contratos HTTP Esperados

#### Happy Path (Compra Aprobada)

```gherkin
CASO-1: GET /api/v1/tickets/{ticketId} retorna 200
  Dado que:    ticketId viene de respuesta de pago exitoso
  Cuando:      consulto con X-User-Id del comprador
  Entonces:    recibo 200 con todos campos poblados
  Y:           eventTitle, tier, pricePaid coinciden con reservación
```

#### Negative Path (Compra Rechazada)

```gherkin
CASO-2: No existe ticketId exitoso tras pago DECLINED
  Dado que:    pago fue rechazado (HTTP 400)
  Cuando:      intento acceder a ticketId
  Entonces:    ticketId es nulo o GET retorna 4xx
```

#### Access Control

```gherkin
CASO-3: Comprador diferente no accede al ticket
  Dado que:    ticket pertenece a Comprador A
  Cuando:      intento GET con X-User-Id de Comprador B
  Entonces:    recibo 403 o rechazo equivalente
```

---

### Arquitectura y Dependencias

**Microservicios afectados:**

* `ms-events`: Setup (rooms, events, tiers)
* `ms-ticketing`: Reservations, payments, **tickets** (nuevo)

**Auth:**

* `X-Role: ADMIN` en setup (ms-events)
* `X-User-Id` en reservación, pago, consulta de ticket (ms-ticketing)

---

### Notas de Implementación

> Este feature cubre tres escenarios claros:
> 1. **Happy Path**: Ticket visible, datos correctos, acceso permitido al propietario
> 2. **Negative Path**: Ticket NO existe tras rechazo de pago
> 3. **Access Control**: Ticket NO es accesible para propietario diferente
>
> El endpoint debe ser idempotente (múltiples GETs retornan el mismo ticket).

---

## 3. LISTA DE TAREAS

> Checklist accionable para la automatización en Karate. Marcar cada ítem (`[x]`) al completarlo.

### Fase 1: Implementación Karate

#### Feature Karate Principal

* [ ] Crear `ticket-visibility-and-access-control.feature` en `src/test/java/api/ticket-visibility-and-access-control/`
* [ ] Reutilizar Background y setup completo de SPEC-001 (Room → Event → Tier → Publish)
* [ ] Implementar **Scenario 1: Happy Path - Ticket Visible for Owner**
  * [ ] Crear reservación (Buyer 1)
  * [ ] Procesar pago APPROVED
  * [ ] Extraer `ticketId` de respuesta de pago
  * [ ] Realizar `GET /api/v1/tickets/{ticketId}` con `X-User-Id` de Buyer 1
  * [ ] Validar respuesta 200
  * [ ] Validar contrato: `eventId`, `tier`, `pricePaid`, `buyerEmail`, `purchasedAt`
  * [ ] Validar consistencia: `eventTitle` coincide con setup, `tier` coincide con reservación, `pricePaid` coincide con pago
* [ ] Implementar **Scenario 2: Negative Path - No Ticket on Declined Payment**
  * [ ] Crear reservación (Buyer 1)
  * [ ] Procesar pago DECLINED (reutilizar payload de SPEC-002)
  * [ ] Validar que `ticketId` en respuesta es nulo o vacío
  * [ ] Opcionalmente: intentar `GET /tickets/{nulo}` y validar que falla
* [ ] Implementar **Scenario 3: Access Control - Buyer B Cannot Access Buyer A's Ticket**
  * [ ] Completar Scenario 1 (Buyer A tiene ticket válido)
  * [ ] Con diferente `X-User-Id` (Buyer B), intentar `GET /api/v1/tickets/{ticketIdA}`
  * [ ] Validar que respuesta es 403 o equivalente (4xx)

#### Payloads y Schemas

* [ ] Reutilizar todos los payloads de SPEC-001
* [ ] Reutilizar payload de pago rechazado de SPEC-002
* [ ] Crear schema JSON para respuesta GET /tickets:

  ```json
  {
    "ticketId": "#uuid",
    "eventId": "#uuid",
    "eventTitle": "#string",
    "eventDate": "#string",
    "tier": "#string",
    "pricePaid": "#number",
    "status": "#string",
    "buyerEmail": "#string",
    "reservationId": "#uuid",
    "purchasedAt": "#string"
  }
  ```

#### Test Runner

* [ ] Crear `TicketVisibilityAndAccessControlTest.java` en `src/test/java/runners/`
* [ ] Apuntar a `classpath:api/ticket-visibility-and-access-control/ticket-visibility-and-access-control.feature`

#### Documentación

* [ ] Crear `README.md` en `src/test/java/api/ticket-visibility-and-access-control/`
  * [ ] Descripción de escenarios
  * [ ] Inventory de payloads y schemas
  * [ ] Instrucciones de ejecución
  * [ ] Notas sobre validación de acceso

### Fase 2: QA y Validación

* [ ] Ejecutar feature localmente contra ambiente Docker
* [ ] Validar que Scenario 1 (happy path) ejecuta en verde
* [ ] Validar que Scenario 2 (negative path) ejecuta en verde
* [ ] Validar que Scenario 3 (access control) ejecuta en verde
* [ ] Documentar el contrato real observado para GET /tickets en caso de diferencias
* [ ] Obtener reporte Karate final

### Fase 3: Cierre

* [ ] Actualizar el endpoint `GET /api/v1/tickets/{ticketId}` en documentación si contrato difiere
* [ ] Actualizar este spec a status `IMPLEMENTED` cuando corresponda
* [ ] Realizar commit final con mensaje: `feat: ticket-visibility-and-access-control (SPEC-004)`

---

### Dependencias Internas

El flujo es secuencial dentro de cada scenario:

**Scenario 1:**
`Setup (HU-01~04) → Reservation (HU-05) → Payment APPROVED (HU-06) → GET Ticket (HU-07)`

**Scenario 2:**
`Setup (HU-01~04) → Reservation (HU-05) → Payment DECLINED (HU-06 alt) → Validar ausencia ticket (HU-08)`

**Scenario 3:**
`Scenario 1 completado → GET Ticket con Buyer B (HU-09)`

Cada scenario es independiente en términos de data (UUIDs únicos), pero comparten el patrón de setup.

---

## Aprobación y Cambios

| Versión | Fecha      | Autor       | Cambios                                          |
| ------- | ---------- | ----------- | ------------------------------------------------ |
| 1.0     | 2026-04-06 | qa-architect | Creación spec APPROVED con 3 scenarios (HU-07/08/09) |

---

## Referencias Relacionadas

* **SPEC-001**: Approved Purchase Flow (happy path setup reutilizable)
* **SPEC-002**: Rejected Payment Flow (payload de pago rechazado reutilizable)
* **SPEC-003**: Expiration & Release Flow (validaciones SQL análogas)
* **Diccionario de Dominio**: `.github/copilot-instructions.md` (términos canónicos)