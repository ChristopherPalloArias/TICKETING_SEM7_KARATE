---
id: SPEC-001
status: APPROVED
feature: ticketing-karate-purchase-approved-flow
created: 2026-04-06
updated: 2026-04-06
author: spec-generator
version: "1.2"
related-specs: []
---

# Spec: Ticketing MVP — Karate Approved Purchase Flow

> **Estado:** `APPROVED`
> **Ciclo de vida:** DRAFT → APPROVED → IN_PROGRESS → IMPLEMENTED → DEPRECATED

---

## 1. REQUERIMIENTOS

### Descripción
Automatización Karate de la ruta feliz del flujo de compra aprobada del MVP de Ticketing. La automatización debe demostrar que el sistema es capaz de preparar los datos empresariales mínimos requeridos para una venta, crear una reservación para un comprador, y procesar un pago simulado aprobado que termine con una compra confirmada y un ticket generado. Todo esto sin usar base de datos (SQL) ni validaciones asíncronas, priorizando el flujo principal secuencial.

### Requerimiento de Negocio
Este challenge consiste en implementar una automatización DSL de Karate estable para la ruta principal feliz del flujo de compra de Ticketing MVP. La solución debe usar los contratos reales y comportamientos detectados en el código auditado de microservicios. El enfoque de esta primera característica es estabilidad, corrección y alineación con la implementación real, cubriendo única y exclusivamente el happy path.

Este challenge representa el valor transaccional central del MVP:
- Evento válido disponible para venta
- Configuración válida de tier
- Creación de reservación
- Procesamiento de pago aprobado
- Compra confirmada con generación de ticket

---

### Historias de Usuario

#### HU-01: Crear Sala para Evento

```text
Como:        Administrador del sistema
Quiero:      Crear una sala de eventos con capacidad definida
Para:        Usar esta sala como contenedor para crear eventos de ticketing

Prioridad:   Alta
Estimación:  XS
Dependencias: Ninguna
Capa:        API / Automatización
````

#### Criterios de Aceptación — HU-01

**Happy Path**

```gherkin
CRITERIO-1.1: Crear sala exitosamente con credenciales administrativas
  Dado que:    existe un ambiente local/Docker con endpoint de salas disponible
  Cuando:      enviamos POST /api/v1/rooms con encabezado X-Role: ADMIN y payload válido
  Entonces:    recibimos respuesta 201 con identificador de sala no nulo y campos de capacidad poblados
```

---

#### HU-02: Crear Evento en Estado Borrador

```text
Como:        Administrador del sistema
Quiero:      Crear un evento en estado DRAFT asociado a una sala existente
Para:        Poder configurar tiers de precios y luego publicarlo

Prioridad:   Alta
Estimación:  S
Dependencias: HU-01
Capa:        API / Automatización
```

#### Criterios de Aceptación — HU-02

**Happy Path**

```gherkin
CRITERIO-2.1: Crear evento en estado DRAFT exitosamente
  Dado que:    disponemos de una sala válida creada previamente
  Cuando:      enviamos POST /api/v1/events con X-Role: ADMIN, nombre único, fecha futura y capacidad válida
  Entonces:    recibimos respuesta 201 con identificador de evento, estado DRAFT, y asociación correcta a sala
```

---

#### HU-03: Configurar Tier de Precio para Evento

```text
Como:        Administrador del sistema
Quiero:      Asignar uno o más tiers a un evento en DRAFT
Para:        Permitir que compradores seleccionen y paguen mediante diferentes opciones de precio

Prioridad:   Alta
Estimación:  S
Dependencias: HU-02
Capa:        API / Automatización
```

#### Criterios de Aceptación — HU-03

**Happy Path**

```gherkin
CRITERIO-3.1: Crear tier GENERAL con precio y cuota válida
  Dado que:    disponemos de un evento en estado DRAFT
  Cuando:      enviamos POST /api/v1/events/{eventId}/tiers con X-Role: ADMIN y un tier GENERAL válido
  Entonces:    recibimos respuesta 201 con identificador de tier, tipo GENERAL, precio poblado y cuota respetada
```

---

#### HU-04: Publicar Evento para Venta

```text
Como:        Administrador del sistema
Quiero:      Transicionar un evento de estado DRAFT a PUBLISHED
Para:        Que el evento esté disponible para reservaciones de compradores

Prioridad:   Alta
Estimación:  XS
Dependencias: HU-02, HU-03
Capa:        API / Automatización
```

#### Criterios de Aceptación — HU-04

**Happy Path**

```gherkin
CRITERIO-4.1: Publicar evento cuando cumple precondiciones
  Dado que:    el evento existe en DRAFT y tiene al menos un tier configurado
  Cuando:      enviamos PATCH /api/v1/events/{eventId}/publish con X-Role: ADMIN
  Entonces:    recibimos respuesta 200 con evento en estado PUBLISHED y sin cuerpo de solicitud requerido
```

---

#### HU-05: Crear Reservación para Comprador

```text
Como:        Comprador del sistema
Quiero:      Crear una reservación en un evento publicado con un tier específico
Para:        Asegurar mi acceso a entradas antes de procesar el pago

Prioridad:   Crítica
Estimación:  M
Dependencias: HU-04
Capa:        API / Automatización
```

#### Criterios de Aceptación — HU-05

**Happy Path**

```gherkin
CRITERIO-5.1: Crear reservación exitosamente con datos válidos
  Dado que:    el evento está PUBLISHED, el tier es válido, y controlamos un X-User-Id único
  Cuando:      enviamos POST /api/v1/reservations con X-User-Id, eventId, tierId y buyerEmail
  Entonces:    recibimos respuesta 201 con identificador no nulo, estado PENDING, y validUntilAt poblado
```

---

#### HU-06: Procesar Pago Aprobado para Reservación

```text
Como:        Sistema de Ticketing
Quiero:      Procesar un pago aprobado asociado a una reservación pendiente
Para:        Confirmar la compra, generar el ticket y completar la transacción

Prioridad:   Crítica
Estimación:  M
Dependencias: HU-05
Capa:        API / Automatización
```

#### Criterios de Aceptación — HU-06

**Happy Path**

```gherkin
CRITERIO-6.1: Procesar pago MOCK aprobado exitosamente
  Dado que:    la reservación existe en estado PENDING y el X-User-Id coincide con el creador
  Cuando:      enviamos POST /api/v1/reservations/{reservationId}/payments con paymentMethod MOCK y status APPROVED
  Entonces:    recibimos respuesta 200 con status CONFIRMED, ticketId no nulo, y el objeto ticket generado en la respuesta
```

---

### Reglas de Negocio (Happy Path)

1. **Flujo Secuencial Exclusivo:** Cada entidad se crea y encadena hacia la siguiente (Room → Event → Tier → Publish → Reservation → Payment).
2. **Setup por API:** Toda la preparación de datos se hace mediante endpoints. Sin llamados SQL ni colas asíncronas.
3. **Propiedad Constante:** El identificador `X-User-Id` inyectado en el paso de creación de reservación se mantiene intacto para el pago, garantizando la confirmación.
4. **Evento Publicado:** La reservación solo se puede crear si el evento ya está publicado.
5. **Tier Válido:** El tier debe pertenecer al evento y tener inventario/cuota válida para la operación.
6. **Pago Aprobado:** Un pago con `status = APPROVED` debe producir una compra confirmada y un ticket generado.

---

## 2. DISEÑO API

### API Endpoints

#### POST /api/v1/rooms

* **Descripción**: Crea una nueva sala de eventos para usar como contenedor de eventos.
* **Auth requerida**: Sí (`X-Role: ADMIN`)
* **Request Body**:

  ```json
  {
    "name": "string (obligatorio)",
    "maxCapacity": "number (obligatorio, > 0)"
  }
  ```
* **Response**: Devuelve la entidad creada con un identificador no nulo, usando el nombre real definido por la implementación, y el campo `maxCapacity` poblado.

---

#### POST /api/v1/events

* **Descripción**: Crea un nuevo evento en estado DRAFT asociado a una sala.
* **Auth requerida**: Sí (`X-Role: ADMIN`)
* **Request Body**:

  ```json
  {
    "roomId": "string (uuid, obligatorio)",
    "title": "string (obligatorio, único)",
    "description": "string (obligatorio)",
    "date": "ISO8601 (obligatorio, fecha futura)",
    "capacity": "number (obligatorio, <= maxCapacity de la sala)",
    "enableSeats": false
  }
  ```
* **Response**: Devuelve el evento creado en estado `DRAFT`, con identificador no nulo y asociación válida a la sala.

---

#### POST /api/v1/events/{eventId}/tiers

* **Descripción**: Configura uno o más tiers de precios para un evento en estado DRAFT.
* **Auth requerida**: Sí (`X-Role: ADMIN`)
* **Path Params**: `eventId` (uuid)
* **Request Body**:

  ```json
  [
    {
      "tierType": "GENERAL",
      "price": "#number (> 0)",
      "quota": "#number (> 0, <= capacity del evento)"
    }
  ]
  ```
* **Response**: Confirma la creación del arreglo de tiers para el evento, incluyendo identificadores no nulos para los tiers creados.

---

#### PATCH /api/v1/events/{eventId}/publish

* **Descripción**: Transiciona un evento de DRAFT a PUBLISHED. No requiere cuerpo de solicitud.
* **Auth requerida**: Sí (`X-Role: ADMIN`)
* **Path Params**: `eventId` (uuid)
* **Request Body**: Vacío
* **Response**: Devuelve el evento actualizado con estado `PUBLISHED`.

---

#### POST /api/v1/reservations

* **Descripción**: Crea una reservación para un comprador en un evento publicado.
* **Auth requerida**: Sí (`X-User-Id`)
* **Request Body**:

  ```json
  {
    "eventId": "string (uuid, obligatorio)",
    "tierId": "string (uuid, obligatorio)",
    "buyerEmail": "string (email válido, obligatorio)"
  }
  ```
* **Nota:** `seatIds` existe como campo opcional en el contrato real, pero no será utilizado en esta primera implementación.
* **Response**:

  ```json
  {
    "id": "#uuid",
    "eventId": "#uuid",
    "tierId": "#uuid",
    "buyerId": "#uuid",
    "status": "PENDING",
    "createdAt": "#string",
    "updatedAt": "#string",
    "validUntilAt": "#string"
  }
  ```

---

#### POST /api/v1/reservations/{reservationId}/payments

* **Descripción**: Procesa un pago aprobado para una reservación pendiente.
* **Auth requerida**: Sí (`X-User-Id` del dueño de la reservación)
* **Path Params**: `reservationId` (uuid)
* **Request Body**:

  ```json
  {
    "amount": "#number (> 0)",
    "paymentMethod": "MOCK",
    "status": "APPROVED"
  }
  ```
* **Response**:

  ```json
  {
    "reservationId": "#uuid",
    "status": "CONFIRMED",
    "ticketId": "#uuid",
    "message": "#string",
    "ticket": {
      "id": "#uuid",
      "eventId": "#uuid",
      "eventTitle": "#string",
      "eventDate": "#string",
      "tierTypeName": "#string",
      "price": "#number",
      "status": "#string",
      "buyerEmail": "#string",
      "reservationId": "#uuid"
    },
    "timestamp": "#string"
  }
  ```

---

### Arquitectura y Dependencias

**Microservicios afectados:**

* `ms-events`: Endpoints de salas (`rooms`), eventos (`events`), tiers
* `ms-ticketing`: Endpoints de reservaciones (`reservations`) y pagos (`payments`)

**Integración y Auth:**

* Contexto administrativo vía encabezado `X-Role: ADMIN` en `ms-events`
* Contexto de comprador vía encabezado `X-User-Id` en `ms-ticketing`

---

### Notas de Implementación

> Este feature cubre exclusivamente el happy path.
>
> La configuración se realiza 100% mediante endpoints en cascada (setup por API).
>
> En Karate se deben usar aserciones estructurales dinámicas para valores generados como IDs y timestamps, y aserciones estrictas para estados de negocio como `DRAFT`, `PUBLISHED`, `PENDING` y `CONFIRMED`.
>
> Esta primera implementación no debe incluir SQL, RabbitMQ, scheduler, expiración, concurrencia, ni escenarios negativos.

---

## 3. LISTA DE TAREAS

> Checklist accionable para la automatización en Karate. Marcar cada ítem (`[x]`) al completarlo.

### Fase 1: Implementación Karate

#### Setup y Helpers

* [ ] Crear o reutilizar contexto de administrador con header `X-Role: ADMIN`.
* [ ] Configurar inyección dinámica de un único `X-User-Id` reutilizable durante todo el flujo.
* [ ] Preparar payload requerido para Room Create con el contrato real confirmado.
* [ ] Preparar payloads requeridos para Event Create, Tier Create, Reservation Create y Payment Request con los nombres de campos validados (`date`, `capacity`, `tierType`).

#### Feature Karate Principal

* [ ] Crear orquestación secuencial en `purchase-approved-flow.feature`.

  * [ ] HU-01: `POST /api/v1/rooms` y extraer identificador de sala.
  * [ ] HU-02: `POST /api/v1/events` enviando `date` y `capacity`, y extraer `eventId`.
  * [ ] HU-03: `POST /api/v1/events/{eventId}/tiers` enviando array con `tierType`, y extraer identificador de tier.
  * [ ] HU-04: `PATCH /api/v1/events/{eventId}/publish`.
  * [ ] HU-05: `POST /api/v1/reservations` extrayendo `id` y validando `status = PENDING`, `createdAt`, `updatedAt`, `validUntilAt`.
  * [ ] HU-06: `POST /api/v1/reservations/{id}/payments` verificando ticket anidado, `status = CONFIRMED`, `reservationId` y `timestamp`.

### Fase 2: QA y Validación

* [ ] Ejecutar el feature localmente contra ambiente Docker.
* [ ] Obtener reporte Karate en verde exclusivo para happy path.

### Fase 3: Cierre

* [ ] Actualizar estado del feature a `IMPLEMENTED` cuando corresponda.
* [ ] Realizar commit final a la rama de trabajo.

---

### Dependencias Internas

El flujo es estrictamente secuencial:

`HU-01 (Room) → HU-02 (Event Draft) → HU-03 (Tier) → HU-04 (Publish) → HU-05 (Reservation PENDING) → HU-06 (Payment CONFIRMED)`

No se deben introducir dependencias asíncronas ni pasos externos a este recorrido.

---

## Aprobación y Cambios

| Versión | Fecha      | Autor          | Cambios                                                                                        |
| ------- | ---------- | -------------- | ---------------------------------------------------------------------------------------------- |
| 1.0     | 2026-04-06 | spec-generator | Creación spec inicial DRAFT                                                                    |
| 1.1     | 2026-04-06 | qa-architect   | Fijación only-happy-path y alineación parcial con contratos auditados                          |
| 1.2     | 2026-04-06 | qa-architect   | Aprobación final, limpieza de ambigüedades y alineación con el flujo inicial de implementación |
