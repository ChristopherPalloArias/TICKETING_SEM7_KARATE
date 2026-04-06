---
id: SPEC-003
status: APPROVED
feature: ticketing-karate-expiration-release-flow
created: 2026-04-06
updated: 2026-04-06
author: spec-generator
version: "1.1"
related-specs: ["SPEC-001", "SPEC-002"]
---

# Spec: Ticketing MVP — Karate Expiration and Automatic Release Flow

> **Estado:** `APPROVED`
> **Ciclo de vida:** DRAFT → APPROVED → IN_PROGRESS → IMPLEMENTED → DEPRECATED
> **Relacionado con:** `SPEC-001` (Approved Purchase Flow), `SPEC-002` (Rejected Payment Flow)

---

## 1. REQUERIMIENTOS

### Descripción
Automatización Karate del flujo de expiración y liberación automática de inventario en el MVP de Ticketing. Este feature debe demostrar que el sistema libera correctamente la disponibilidad cuando una reservación no se completa exitosamente y evita que el inventario quede bloqueado de forma indefinida.

### Requerimiento de Negocio
Este feature valida una de las reglas de negocio más críticas del MVP: si una reservación no culmina en una compra confirmada, el inventario debe volver a quedar disponible para otros compradores.

La automatización debe demostrar que:
1. se crea una reservación válida,
2. esa reservación entra en un ciclo no exitoso,
3. el mecanismo automático del backend procesa su liberación,
4. y la disponibilidad vuelve a quedar utilizable para un nuevo comprador.

### Alcance funcional de esta spec
Este feature cubre la lógica correspondiente a:
- **HU-04: Reserva y compra de entrada con pago simulado**
- **HU-05: Liberación automática por fallo de pago o expiración**

### Caminos funcionales permitidos
Se permite validar uno o ambos de estos caminos, según lo que resulte más estable contra el runtime real:

- **Path A — Expiración sin pago exitoso**
- **Path B — Pago rechazado seguido de liberación automática**

La implementación puede empezar por el path más estable y extenderse después al otro.

---

### Historias de Usuario cubiertas

#### HU-04: Reserva y compra de entrada con pago simulado

```text id="s4o91d"
Como:        Comprador del sistema
Quiero:      Crear una reservación válida sobre un evento disponible
Para:        Iniciar el ciclo que luego permitirá validar expiración o liberación
````

#### Criterios de Aceptación — HU-04

**Happy Path de preparación**

```gherkin id="z8s83a"
CRITERIO-4.1: Crear reservación exitosamente para iniciar el ciclo
  Dado que:    existe un evento publicado con tier válido y disponibilidad utilizable
  Cuando:      enviamos POST /api/v1/reservations con X-User-Id, eventId, tierId y buyerEmail válidos
  Entonces:    recibimos respuesta 201 con reservación en estado PENDING y ventana de validez poblada
```

---

#### HU-05: Liberación automática por fallo de pago o expiración

```text id="0vm2x1"
Como:        Organizador del evento
Quiero:      Que las entradas bloqueadas por reservas no exitosas se liberen automáticamente
Para:        Evitar que el inventario quede retenido de forma indebida y pueda volver a comprarse
```

#### Criterios de Aceptación — HU-05

**Path A — Expiración**

```gherkin id="r0d7e4"
CRITERIO-5.1: La reservación expira y la disponibilidad se libera
  Dado que:    existe una reservación en estado PENDING cuyo tiempo de validez ya fue superado
  Cuando:      el mecanismo automático del backend procesa la expiración
  Entonces:    la reservación deja de comportarse como una venta activa
  Y            la disponibilidad vuelve a quedar utilizable para otro comprador
```

**Path B — Pago rechazado + liberación**

```gherkin id="sfg95k"
CRITERIO-5.2: El pago rechazado no confirma la compra y la disponibilidad se libera posteriormente
  Dado que:    existe una reservación válida en estado PENDING
  Cuando:      enviamos un pago con status DECLINED y luego actúa el mecanismo automático del backend
  Entonces:    la compra no queda confirmada
  Y            la disponibilidad vuelve a quedar utilizable para otro comprador
```

**Verificación final de liberación**

```gherkin id="z9b30c"
CRITERIO-5.3: Un nuevo comprador puede reservar después de la liberación
  Dado que:    una reservación previa ya fue liberada por expiración o por fallo de pago
  Cuando:      un comprador distinto intenta crear una nueva reservación sobre el mismo inventario
  Entonces:    la nueva reservación se crea exitosamente
```

---

### Reglas de Negocio

1. **Bloqueo inicial:** Una reservación válida bloquea disponibilidad al momento de su creación.
2. **Validez temporal:** Una reservación posee una ventana de validez (`validUntilAt`) que delimita su vigencia.
3. **Pago rechazado:** Un pago con `status = DECLINED` no confirma la compra.
4. **Liberación automática:** El backend debe liberar automáticamente la disponibilidad de una reservación no exitosa.
5. **Disponibilidad restaurada:** Una vez liberada la reservación, otro comprador debe poder reservar nuevamente.
6. **No asumir estados internos no confirmados:** La implementación no debe asumir estados como `RELEASED` si no están confirmados por runtime real.
7. **Validación realista:** Si la liberación no puede demostrarse completamente por HTTP, se permite validación por SQL como soporte técnico.

---

## 2. DISEÑO API

### Endpoints de setup reutilizados

Los siguientes endpoints se reutilizan desde los flujos ya implementados:

#### POST /api/v1/rooms

* **Descripción:** Crear sala para el evento
* **Auth requerida:** Sí (`X-Role: ADMIN` y cualquier header adicional confirmado por runtime)
* **Response esperada:** 201 con identificador no nulo

#### POST /api/v1/events

* **Descripción:** Crear evento base
* **Auth requerida:** Sí (`X-Role: ADMIN` y cualquier header adicional confirmado por runtime)
* **Request Body:**

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
* **Response esperada:** 201 con evento válido

#### POST /api/v1/events/{eventId}/tiers

* **Descripción:** Configurar tier GENERAL
* **Auth requerida:** Sí (`X-Role: ADMIN`)
* **Request Body:**

  ```json
  [
    {
      "tierType": "GENERAL",
      "price": 100.00,
      "quota": 40
    }
  ]
  ```
* **Response esperada:** 201 con tier válido

#### PATCH /api/v1/events/{eventId}/publish

* **Descripción:** Publicar evento
* **Auth requerida:** Sí (`X-Role: ADMIN`)
* **Response esperada:** 200 con evento publicado

---

### Endpoints del flujo de reservación

#### POST /api/v1/reservations

* **Descripción:** Crear reservación inicial
* **Auth requerida:** Sí (`X-User-Id`)
* **Request Body:**

  ```json
  {
    "eventId": "uuid",
    "tierId": "uuid",
    "buyerEmail": "string"
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

#### POST /api/v1/reservations/{reservationId}/payments

* **Descripción:** Procesar pago rechazado cuando se use Path B
* **Auth requerida:** Sí (`X-User-Id`)
* **Request Body:**

  ```json
  {
    "amount": 100.00,
    "paymentMethod": "MOCK",
    "status": "DECLINED"
  }
  ```
* **Contrato real conocido desde SPEC-002:**

  * **HTTP:** `400`
  * **Body:**

    ```json
    {
      "error": "#string",
      "reservationId": "#uuid",
      "status": "PAYMENT_FAILED",
      "timestamp": "#string"
    }
    ```

---

### Verificación de liberación

#### Validación por HTTP

Si existe un endpoint real y utilizable para observar disponibilidad o estado, puede usarse para validar:

* que la reservación dejó de comportarse como activa,
* o que la disponibilidad volvió a quedar accesible.

#### Validación por nueva reservación

La prueba preferida para validar liberación es:

1. crear una primera reservación,
2. dejar que ocurra expiración o liberación,
3. intentar crear una segunda reservación con otro comprador,
4. confirmar que la segunda reservación sí se crea.

#### Validación por SQL

Se permite SQL **solo si** el backend no expone una forma suficiente y estable de probar la liberación por HTTP.
SQL puede usarse para validar:

* estado final de la reservación,
* efecto sobre disponibilidad,
* o consistencia del inventario restaurado.

---

### Nota técnica

Este feature depende de comportamiento asincrónico real del backend.
No se deben inventar:

* triggers manuales del scheduler,
* endpoints de administración del tiempo,
* endpoints de availability si no existen,
* ni estados finales internos no confirmados por runtime.

---

## 3. ESTRATEGIA DE IMPLEMENTACIÓN

### Estrategia recomendada

Implementar primero **un solo path estable**.

Orden recomendado:

1. Reutilizar setup del approved flow
2. Crear una reservación
3. Elegir uno de los dos caminos:

   * expiración, o
   * pago rechazado + liberación
4. Validar liberación con el método más confiable:

   * preferentemente por segunda reservación exitosa,
   * o por HTTP observacional,
   * o por SQL si hace falta

### Prioridad recomendada

1. **Path B — Pago rechazado + liberación**

   * ya tienes el contrato del rechazo
   * reaprovecha el flujo rechazado implementado
2. **Path A — Expiración**

   * más costoso por tiempo y scheduler

---

## 4. LISTA DE TAREAS

### Fase 0: Descubrimiento mínimo

* [ ] Confirmar si existe endpoint usable para consultar disponibilidad o estado
* [ ] Confirmar si basta una segunda reservación exitosa como prueba de liberación
* [ ] Confirmar si SQL será necesario

### Fase 1: Implementación base

* [ ] Reutilizar setup ya estable de sala, evento, tier y publish
* [ ] Crear reservación inicial
* [ ] Implementar Path B o Path A, empezando por el más estable
* [ ] Esperar el tiempo o el ciclo real que requiera el backend
* [ ] Validar liberación con el mecanismo real disponible

### Fase 2: Validación

* [ ] Confirmar que la primera reservación no permanece como venta efectiva
* [ ] Confirmar que la disponibilidad vuelve a quedar utilizable
* [ ] Confirmar que un comprador distinto puede volver a reservar

### Fase 3: Cierre

* [ ] Crear `ExpirationReleaseFlowTest.java`
* [ ] Guardar evidencia de ejecución
* [ ] Actualizar la spec a `IMPLEMENTED` cuando el flujo pase

---

## 5. RIESGOS IDENTIFICADOS

| Riesgo                                                    | Probabilidad | Impacto | Mitigación                                                  |
| --------------------------------------------------------- | -----------: | ------: | ----------------------------------------------------------- |
| El scheduler tiene tiempos poco prácticos para prueba     |         Alta |    Alto | Empezar por el path más estable y documentar tiempos reales |
| No existe endpoint claro de observación de disponibilidad |        Media |    Alto | Validar por segunda reservación o SQL                       |
| El backend usa estados internos distintos a los supuestos |        Media |    Alto | Validar contra runtime real                                 |
| La prueba se vuelve lenta o frágil por asincronía         |         Alta |   Medio | Mantener alcance pequeño y validar con evidencia concreta   |

---

## 6. DEPENDENCIAS INTERNAS

Flujo recomendado mínimo:

`Setup API → Reservación inicial → Rechazo o expiración → Liberación automática → Segunda reservación o validación equivalente`

---

## Aprobación y Cambios

| Versión | Fecha      | Autor          | Cambios                                                                                       |
| ------- | ---------- | -------------- | --------------------------------------------------------------------------------------------- |
| 1.0     | 2026-04-06 | spec-generator | Creación spec inicial DRAFT                                                                   |
| 1.1     | 2026-04-06 | qa-architect   | Limpieza de supuestos, alineación con HU-04/HU-05 y aprobación para implementación progresiva |

```