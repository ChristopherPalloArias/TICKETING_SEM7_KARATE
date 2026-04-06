---
id: SPEC-002
status: IMPLEMENTED
feature: ticketing-karate-rejected-payment-flow
created: 2026-04-06
updated: 2026-04-06
author: spec-generator
version: "1.1"
related-specs: ["SPEC-001"]
---

# Spec: Ticketing MVP — Karate Rejected Payment Flow

> **Estado:** `IMPLEMENTED`
> **Ciclo de vida:** DRAFT → APPROVED → IN_PROGRESS → IMPLEMENTED → DEPRECATED
> **Relacionado con:** `SPEC-001` (Approved Purchase Flow)

---

## 1. REQUERIMIENTOS

### Descripción
Automatización Karate del flujo de pago rechazado del MVP de Ticketing. Esta automatización debe demostrar que el sistema rechaza correctamente un pago con estado `DECLINED` y no confirma la compra ni produce un resultado exitoso equivalente al flujo aprobado. Reutiliza el mismo setup estable ya demostrado en el flujo de compra aprobada.

### Requerimiento de Negocio
Este feature consiste en implementar una automatización DSL de Karate para la ruta de rechazo de pago del flujo de compra del Ticketing MVP. La solución debe usar los mismos microservicios y contratos base del flujo aprobado, pero validar el comportamiento cuando el pago es rechazado. El enfoque es probar el resultado negativo de negocio manteniendo la estabilidad operativa del setup.

Este feature valida el resultado empresarial correcto de un pago rechazado:
- setup de datos válido completado,
- reservación válida creada en estado `PENDING`,
- pago procesado con estado `DECLINED`,
- confirmación de que la compra no fue confirmada,
- confirmación de que no se obtuvo un resultado exitoso equivalente al flujo aprobado.

---

### Historias de Usuario

#### HU-01: Creación de evento de obra de teatro (Setup)

```text
Como:        Administrador del sistema
Quiero:      Crear el contexto base del evento para habilitar la venta
Para:        Poder preparar el flujo de reservación y pago

Prioridad:   Alta
Estimación:  XS
Dependencias: Ninguna
Capa:        API / Automatización
````

#### Criterios de Aceptación — HU-01

**Happy Path**

```gherkin
CRITERIO-1.1: Preparar evento exitosamente con credenciales administrativas
  Dado que:    existe un ambiente local/Docker con endpoints de setup disponibles
  Cuando:      ejecutamos el setup administrativo por API
  Entonces:    obtenemos una sala válida, un evento válido, un tier válido y un evento publicado listo para reservación
```

---

#### HU-02: Configuración de tiers y precios por evento (Setup)

```text
Como:        Administrador del sistema
Quiero:      Configurar un tier válido para el evento
Para:        Permitir la creación posterior de una reservación

Prioridad:   Alta
Estimación:  XS
Dependencias: HU-01
Capa:        API / Automatización
```

#### Criterios de Aceptación — HU-02

**Happy Path**

```gherkin
CRITERIO-2.1: Configurar tier GENERAL exitosamente
  Dado que:    existe un evento válido creado previamente
  Cuando:      enviamos la configuración del tier GENERAL con precio y cuota válidos
  Entonces:    obtenemos un identificador de tier no nulo y el evento queda listo para publicación
```

---

#### HU-04: Reserva y compra de entrada con pago simulado

```text
Como:        Comprador del sistema
Quiero:      Crear una reservación válida y procesar un pago rechazado
Para:        Validar que el sistema no confirme la compra cuando el pago falla

Prioridad:   Crítica
Estimación:  M
Dependencias: HU-01, HU-02
Capa:        API / Automatización
```

#### Criterios de Aceptación — HU-04

**Happy Path del setup + rechazo esperado**

```gherkin
CRITERIO-4.1: Crear reservación exitosamente con datos válidos
  Dado que:    el evento está publicado, el tier es válido y controlamos un X-User-Id único
  Cuando:      enviamos POST /api/v1/reservations con X-User-Id, eventId, tierId y buyerEmail
  Entonces:    recibimos respuesta 201 con identificador no nulo y estado PENDING
```

```gherkin
CRITERIO-4.2: Procesar pago MOCK rechazado y confirmar que no se confirma compra
  Dado que:    la reservación existe en estado PENDING y el X-User-Id coincide con el creador
  Cuando:      enviamos POST /api/v1/reservations/{reservationId}/payments con paymentMethod MOCK, status DECLINED y amount válido
  Entonces:    recibimos una respuesta de rechazo alineada con el runtime real
  Y            la compra no queda confirmada
  Y            no se valida ticket exitoso como en el flujo aprobado
```

---

### Reglas de Negocio

1. **Setup Idéntico al flujo aprobado:** La preparación de sala, evento, tier y publicación debe ser equivalente al flujo aprobado.
2. **X-User-Id constante:** El mismo `X-User-Id` utilizado en la reservación debe reutilizarse en el pago rechazado.
3. **Pago rechazado:** Un pago con `status = DECLINED` debe resultar en un rechazo de negocio.
4. **No confirmación de compra:** Un pago rechazado no debe producir un resultado exitoso equivalente a `CONFIRMED`.
5. **No validación de ticket exitoso:** Un pago rechazado no debe validarse con el mismo contrato exitoso del flujo aprobado.
6. **Contrato real primero:** La respuesta del endpoint de pago rechazado debe validarse con base en el comportamiento real del runtime, no por simetría automática con el flujo aprobado.

---

## 2. DISEÑO API

### API Endpoints

#### Setup administrativo reutilizado desde el flujo aprobado

Los siguientes endpoints se reutilizan exactamente como parte del setup ya probado en `SPEC-001`:

* `POST /api/v1/rooms`
* `POST /api/v1/events`
* `POST /api/v1/events/{eventId}/tiers`
* `PATCH /api/v1/events/{eventId}/publish`

**Notas de reutilización:**

* El setup debe seguir apuntando directamente a `ms-events`.
* Deben mantenerse los headers administrativos reales (`X-Role: ADMIN` y cualquier header adicional ya confirmado por runtime).
* No se deben reintroducir supuestos nuevos para estos contratos.

---

#### POST /api/v1/reservations

* **Descripción:** Crea una reservación para un comprador en un evento publicado.
* **Auth requerida:** Sí (`X-User-Id`)
* **Request Body:**

  ```json
  {
    "eventId": "string (uuid)",
    "tierId": "string (uuid)",
    "buyerEmail": "string (email válido)"
  }
  ```
* **Response esperada:**

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
* **Notas:** Reutiliza el mismo contrato exitoso ya validado en el flujo aprobado.

---

#### POST /api/v1/reservations/{reservationId}/payments

* **Descripción:** Procesa un pago rechazado para una reservación pendiente.
* **Auth requerida:** Sí (`X-User-Id` del dueño de la reservación)
* **Path Params:** `reservationId`
* **Request Body**:

  ```json
  {
    "amount": 100.00,
    "paymentMethod": "MOCK",
    "status": "DECLINED"
  }
  ```

* **Response 400**:

  ```json
  {
    "error": "#string",
    "reservationId": "#uuid",
    "status": "PAYMENT_FAILED",
    "timestamp": "#string"
  }
  ```

* **Notas:** El backend no confirma la compra ni genera ticket exitoso. La reservación queda en estado `PAYMENT_FAILED` y permanece activa temporalmente hasta que actúe el mecanismo de expiración/liberación.

### Diferencias clave respecto al flujo aprobado

| Aspecto                              | Approved Flow            | Rejected Payment Flow              |
| ------------------------------------ | ------------------------ | ---------------------------------- |
| `status` enviado al endpoint de pago | `APPROVED`               | `DECLINED`                         |
| Resultado esperado                   | Compra confirmada        | Rechazo de negocio                 |
| Validación de `ticketId`             | Obligatoria              | No debe asumirse                   |
| Validación de contrato exitoso       | Sí                       | No                                 |
| Contrato de respuesta                | Ya descubierto y estable | Debe validarse contra runtime real |

---

### Notas de Implementación

> Este feature cubre el flujo de rechazo de pago reutilizando el setup ya validado en el flujo aprobado.

> Riesgo principal: el contrato exacto de respuesta del pago rechazado debe confirmarse en runtime real antes de fijar el match definitivo.

> La implementación debe:
>
> 1. reutilizar el setup estable,
> 2. ejecutar el pago con `DECLINED`,
> 3. observar el response real,
> 4. ajustar la aserción al contrato real del backend,
> 5. documentar cualquier diferencia contra supuestos previos.

> No usar SQL, RabbitMQ, scheduler, expiration, concurrencia ni seats en esta versión.

---

## 3. LISTA DE TAREAS

### Fase 1: Reutilización del setup estable

* [ ] Reutilizar el flujo ya validado para:

  * creación de sala
  * creación de evento
  * configuración de tier
  * publicación de evento
* [ ] Reutilizar el mismo enfoque de `X-User-Id` controlado y persistente.

### Fase 2: Implementación del flujo rechazado

* [ ] Crear `payment-rejected-flow.feature`
* [ ] Reutilizar el setup aprobado hasta la creación de reservación
* [ ] Enviar el pago con:

  * `paymentMethod = MOCK`
  * `status = DECLINED`
  * `amount` válido

### Fase 3: Descubrimiento del contrato runtime

* [ ] Ejecutar el flujo contra el backend real
* [ ] Capturar status code real del pago rechazado
* [ ] Capturar response body real del pago rechazado
* [ ] Ajustar el match del feature al contrato real observado
* [ ] Documentar el contrato final descubierto en esta spec si aplica

### Fase 4: Validación final

* [ ] Confirmar que la reservación se crea correctamente
* [ ] Confirmar que el pago rechazado no usa el contrato exitoso del flujo aprobado
* [ ] Confirmar que no se valida compra confirmada
* [ ] Confirmar que no se valida ticket exitoso

### Fase 5: Cierre

* [ ] Crear `RejectedPaymentFlowTest.java`
* [ ] Ejecutar la suite localmente
* [ ] Guardar evidencia de ejecución
* [ ] Actualizar estado a `IMPLEMENTED` cuando pase

---

### Dependencias Internas

El flujo sigue siendo secuencial y reutiliza el setup del approved flow:

`Setup API → Reservación PENDING → Pago DECLINED`

---

### Riesgos Identificados

| Riesgo                                                              | Probabilidad | Impacto | Mitigación                                          |
| ------------------------------------------------------------------- | -----------: | ------: | --------------------------------------------------- |
| Contrato de respuesta rechazado distinto al esperado                |         Alta |    Alto | Validar contra runtime real antes de fijar el match |
| Pérdida del `X-User-Id` entre reservación y pago                    |        Media |    Alto | Reutilizar exactamente el mismo UUID                |
| Reutilización incorrecta del contrato aprobado                      |        Media |    Alto | No copiar el match exitoso al flujo rechazado       |
| Diferencias de runtime entre ambiente local y expectativas teóricas |        Media |   Medio | Ajustar sobre respuesta real del backend            |

---

## Aprobación y Cambios

| Versión | Fecha      | Autor          | Cambios                                                                                           |
| ------- | ---------- | -------------- | ------------------------------------------------------------------------------------------------- |
| 1.0     | 2026-04-06 | spec-generator | Creación spec inicial DRAFT                                                                       |
| 1.1     | 2026-04-06 | qa-architect   | Alineación con el setup aprobado, limpieza de lenguaje funcional y aprobación para implementación |
| 1.2     | 2026-04-06 | qa-architect   | Contrato runtime real de pago rechazado confirmado: HTTP 400 con `error`, `reservationId`, `status = PAYMENT_FAILED` y `timestamp`. Feature ejecutado con éxito. |