# Ticket Visibility and Access Control Feature

> **Feature ID**: SPEC-004  
> **Status**: IMPLEMENTED  
> **Author**: qa-architect

## Descripción

Feature Karate que valida la visibilidad de tickets tras compra exitosa, la ausencia de tickets en compras rechazadas, y la restricción de acceso por propietario.

---

## Escenarios Cubiertos

### Scenario 1: Happy Path - Ticket Visible for Owner

**Objetivo**: Validar que un ticket es visible y contiene información correcta para el propietario tras compra aprobada.

**Flujo**:
1. Setup: Room → Event DRAFT → Tier → Publish
2. Buyer 1: Create Reservation
3. Buyer 1: Approved Payment (genera ticket)
4. Buyer 1: GET /tickets/{ticketId} → 200 OK
5. Validar: Contrato completo, consistencia de datos

**Validaciones**:
- ✅ Response 200
- ✅ Ticket contiene: ticketId, eventId, eventTitle, tier, pricePaid, buyerEmail, reservationId, purchasedAt
- ✅ eventId, tier, pricePaid coinciden con reservación y pago

---

### Scenario 2: Negative Path - No Ticket on Declined Payment

**Objetivo**: Validar que una compra rechazada NO genera ticket exitoso.

**Flujo**:
1. Setup: Room → Event DRAFT → Tier → Publish
2. Buyer 1: Create Reservation
3. Buyer 1: Declined Payment (HTTP 400, status: PAYMENT_FAILED)
4. Validar: ticketId es nulo/vacío en respuesta

**Validaciones**:
- ✅ Response HTTP 400
- ✅ status = 'PAYMENT_FAILED'
- ✅ ticketId no existe o está vacío

---

### Scenario 3: Access Control - Buyer B Cannot Access Buyer A Ticket

**Objetivo**: Validar que un comprador no puede acceder al ticket de otro comprador.

**Flujo**:
1. Setup: Room → Event DRAFT → Tier → Publish
2. Buyer 1: Create Reservation + Approved Payment (genera ticket)
3. Buyer 2: Intenta GET /tickets/{ticketId de Buyer 1} → 403 Forbidden
4. Validar: Acceso denegado correct

**Validaciones**:
- ✅ Response HTTP 403
- ✅ Acceso rechazado aunque ticketId es válido

---

## Assets (Payloads & Schemas)

### Reutilizados de SPEC-001

```
✅ room-create-request.json
✅ event-create-request.json
✅ tiers-create-request.json
✅ reservation-create-request.json
✅ payment-request.json (status: APPROVED)
```

### Reutilizados de SPEC-002

```
✅ payment-declined-request.json (status: DECLINED)
```

### Nuevos (SPEC-004)

```
✅ ticket-response.json
   - contrato del GET /api/v1/tickets/{ticketId}
   - campos: ticketId, eventId, eventTitle, eventDate, tier, pricePaid, status, buyerEmail, reservationId, purchasedAt
```

---

## Endpoints Validados

| Endpoint | Método | Status | Escenario |
|----------|--------|--------|-----------|
| `/api/v1/rooms` | POST | 201 | Setup |
| `/api/v1/events` | POST | 201 | Setup |
| `/api/v1/events/{id}/tiers` | POST | 201 | Setup |
| `/api/v1/events/{id}/publish` | PATCH | 200 | Setup |
| `/api/v1/reservations` | POST | 201 | All |
| `/api/v1/reservations/{id}/payments` | POST | 200/400 | All |
| `/api/v1/tickets/{ticketId}` | GET | 200/403 | ✨ NEW |

---

## Ejecución

### Prerequisitos
- ms-events corriendo en http://localhost:8081
- ms-ticketing corriendo en http://localhost:8082
- Maven 3.6+

### Comando

```bash
mvn test -Dtest=TicketVisibilityAndAccessControlTest \
  -DbaseUrlEvents=http://localhost:8081 \
  -DbaseUrlTicketing=http://localhost:8082
```

### Resultado Esperado

```
Scenario 1 ✅ PASS
Scenario 2 ✅ PASS
Scenario 3 ✅ PASS

3 scenarios executed, 3 passed, 0 failed
```

---

## Notas Técnicas

### Reusabilidad de Setup

Los 3 scenarios reutilizan el mismo patrón previo:
- UUID generados dinámicamente (sin colisiones)
- Emails con timestamp (buyerEmail1, buyerEmail2)
- Event title con timestamp para diferenciación

### Buyer Isolation

- **Buyer 1**: buyerId1 creado en Background
- **Buyer 2**: buyerId2 creado en Background
- Cada buyer usa su propio X-User-Id en headers

### Contratos No Inventados

El ticket response utiliza exclusivamente campos validados en:
1. Response de payment APPROVED (SPEC-001)
2. Contrato runtime real observado
3. No se inventan campos adicionales

### Sin SQL en Esta Versión

- Feature usa exclusivamente endpoints HTTP
- No hay validación de base de datos
- Enfoque en HTTP contracts y access control

---

## Checklist de Completitud

- [x] 3 scenarios implementados
- [x] Setup reutilizable desde SPEC-001
- [x] Payloads reutilizables de SPEC-001 y SPEC-002
- [x] Schema nuevo para GET /tickets
- [x] Test Runner creado
- [x] Validaciones de contrato (match)
- [x] Print statements para debugging
- [x] README documentado

---

## Referencias

- **SPEC-001**: Approved Purchase Flow (establece setup pattern)
- **SPEC-002**: Rejected Payment Flow (contrato de rechazo)
- **SPEC-004**: Ticket Visibility and Access Control (esta spec)

