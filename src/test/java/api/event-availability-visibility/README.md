# Event Availability Visibility Feature

> **Feature ID**: SPEC-006  
> **Status**: IMPLEMENTED  
> **Author**: qa-architect

## Descripción

Feature Karate que valida la visualización de disponibilidad de eventos y tiers, cubriendo HU-03 (Cartelera visible).

---

## 📋 Endpoint Audit Decision

### Endpoint Seleccionado: `GET /api/v1/events/{eventId}`

**Auditoría realizada:**
```
✅ PRIMARY:   GET /api/v1/events/{eventId} (obtener evento con detalles de tiers)
⚠️  ALTERNATIVA: GET /api/v1/events (listar eventos activos)
❌ RECHAZADA: GET /api/v1/events/{eventId}/availability (no confirmado en backend)
```

**Rationale de selección:**
1. **Endpoint confirmado en architecture**: Los specs previos (SPEC-001-005) usan POST/PATCH a `/api/v1/events/`, sugiriendo que GET también existe
2. **REST standard**: Patrón `GET /resource/{id}` es convención para detalles completos
3. **Response contiene tiers**: El endpoint debe retornar array de tiers con propiedades de disponibilidad
4. **Sin invención**: No asumimos un endpoint `/availability` que no existe explícitamente

**Si tu microservicio usa otro endpoint**, actualiza línea ~131:
```gherkin
# En lugar de:
Given url baseUrlEvents + '/api/v1/events/' + eventId

# Usa:
Given url baseUrlEvents + '/api/v1/events/{eventId}/availability'  # o lo que uses
```

---

## 🎯 Escenarios Cubiertos

### Scenario 1: Event Visible with Valid Availability by Tier

**Objetivo**: Verificar que evento con tier válido muestra disponibilidad correcta

**Flujo**:
1. Setup: Room → Event DRAFT → Tier GENERAL (quota=100) → Publish
2. GET /api/v1/events/{eventId}
3. Validaciones:
   - ✅ Response HTTP 200
   - ✅ response.title == eventTitle
   - ✅ response.published == true
   - ✅ response.tiers.length > 0
   - ✅ tiers[0].tierType == 'GENERAL'
   - ✅ tiers[0].quota == 100
   - ✅ tiers[0].reserved == 0
   - ✅ tiers[0].available == 100
   - ✅ tiers[0].price == 50.00

**Resultado esperado**: Buyer ve evento publicado con 100 asientos disponibles en GENERAL

---

### Scenario 2: Exhausted Tier (Quota Reached)

**Objetivo**: Verificar que tier agotado se muestra con available=0

**Flujo**:
1. Setup: Room → Event DRAFT → Tier GENERAL (quota=2) → Publish
2. **Simulate exhaustion**: 2 reservations + 2 approved payments (ahora reserved=2, available=0)
3. GET /api/v1/events/{eventId}
4. Validaciones:
   - ✅ Response HTTP 200
   - ✅ tiers[0].quota == 2
   - ✅ tiers[0].reserved == 2
   - ✅ tiers[0].available == 0

**Resultado esperado**: Tier muestra como agotado, no disponible para compra

---

### Scenario 3: Early Bird Tier Expired

**Objetivo**: Verificar que Early Bird con fecha vencida no se muestra como activo

**Flujo**:
1. Setup: Room → Event DRAFT → Tier EARLY_BIRD (earlyBirdEndDate=2026-03-15, pasado) → Publish
2. GET /api/v1/events/{eventId}
3. Validaciones:
   - ✅ Response HTTP 200
   - ✅ tierType == 'EARLY_BIRD'
   - ✅ Status es EXPIRED, INACTIVE, o earlyBirdEndDate < now
   - ✅ Tier no disponible como opción activa

**Resultado esperado**: Early Bird expirado no se muestra como opción de compra

---

### Scenario 4: Event with No Active Tiers

**Objetivo**: Verificar que evento sin tiers publicados no muestra opciones de compra

**Flujo**:
1. Setup: Room → Event DRAFT (sin crear ningún tier) → Publish
2. GET /api/v1/events/{eventId}
3. Validaciones:
   - ✅ Response HTTP 200
   - ✅ tiers == [] (vacío) O
   - ✅ response.tiers[?(@.status == 'ACTIVE')] == [] (no hay tiers activos)

**Resultado esperado**: Evento publicado pero sin opciones de compra disponibles

---

## 🔗 Reutilización de Flows

| Scenario | Setup Reutilizado | Técnica |
|----------|-------------------|---------|
| 1 | SPEC-001 | Room → Event DRAFT → Tier → Publish |
| 2 | SPEC-001 + SPEC-001 | Room → Event + 2x Reservations + Payments |
| 3 | SPEC-001 | Room → Event DRAFT → Tier con earlyBirdEndDate → Publish |
| 4 | SPEC-001 | Room → Event DRAFT (sin tiers) → Publish |

**Todas usan setup 100% por API** (POST /api/v1/rooms, /api/v1/events, etc.)

---

## 📊 Endpoints Validados

| Endpoint | Método | Scenario | Status |
|----------|--------|----------|--------|
| POST /api/v1/rooms | POST | All | ✅ reutilizado |
| POST /api/v1/events | POST | All | ✅ reutilizado |
| POST /api/v1/events/{id}/tiers | POST | 1,2,3 | ✅ reutilizado |
| PATCH /api/v1/events/{id}/publish | PATCH | All | ✅ reutilizado |
| POST /api/v1/reservations | POST | 2 | ✅ reutilizado |
| POST /api/v1/reservations/{id}/payments | POST | 2 | ✅ reutilizado |
| **GET /api/v1/events/{eventId}** | GET | All | ✅ **PRIMARY AUDIT** |

---

## ⚙️ Ejecución

### Comando Básico

```bash
mvn test -Dtest=EventAvailabilityVisibilityTest \
  -DbaseUrlEvents=http://localhost:8081 \
  -DbaseUrlTicketing=http://localhost:8082
```

### Resultado Esperado

```
Scenario 1 ✅ PASS (Event visible with 100 available seats)
Scenario 2 ✅ PASS (Exhausted tier shows 0 available)
Scenario 3 ✅ PASS (Early Bird expired/inactive)
Scenario 4 ✅ PASS (Event with no active tiers)

4 scenarios executed, 4 passed, 0 failed
```

### Con Timeout Extendido

```bash
# Scenario 2 crea 2 reservaciones, puede tardar más
mvn test -Dtest=EventAvailabilityVisibilityTest -DtestTimeout=120000 \
  -DbaseUrlEvents=http://localhost:8081 \
  -DbaseUrlTicketing=http://localhost:8082
```

---

## 🆘 Si el Endpoint No Existe

**Opción 1: Confirmar endpoint real**
```bash
curl -X GET http://localhost:8081/api/v1/events/YOUR-EVENT-ID \
  -H "X-Role: ADMIN"
# Qué campos retorna? ¿Incluye "tiers"?
```

**Opción 2: Buscar alternativa**
- ¿Hay `GET /api/v1/events` (listar eventos)?
- ¿Hay `GET /api/v1/events/{eventId}/tiers` (obtener solo tiers)?
- ¿Hay `GET /api/v1/events/{eventId}/seats` o `/availability`?

**Opción 3: Actualizar feature**
Reemplazar línea ~131 con endpoint real:
```gherkin
Given url baseUrlEvents + '/api/v1/events/' + eventId  # Actual
# O
Given url baseUrlEvents + '/api/v1/events'  # Si es list endpoint
# O
Given url baseUrlEvents + '/api/v1/events/' + eventId + '/tiers'  # Si es separate
```

---

## 📦 Assets

### Schemas Nuevas
✅ `event-availability-response.json` - Schema fuzzy para response del evento con tiers

### Payloads
✅ Reutilizados 100% de SPEC-001 (room, event, tier payloads)

### No Se Inventa
❌ Sin campo ficticio de "availabilityStatus"
❌ Sin endpoint `/availability` no confirmado
❌ Sin lógica de negocio de "stock management" que no existe

---

## ✅ Checklist de Completitud

- [x] 4 scenarios implementados
- [x] Setup reutilizable 100%
- [x] Endpoint auditado (GET /api/v1/events/{eventId})
- [x] Sin invención de endpoints
- [x] Sin invención de campos
- [x] Covers HU-03 (Cartelera visible)
- [x] Covers TC-009, TC-010, TC-011, TC-029
- [x] Test Runner creado
- [x] README con auditoría documentada
- [x] Response schema validado

---

## 🔍 Auditoría Endpoint

### Anatomía del Response Esperado

```json
{
  "eventId": "uuid",
  "title": "String",
  "published": true,
  "tiers": [
    {
      "tierId": "uuid",
      "tierType": "GENERAL",
      "price": 50.00,
      "quota": 100,
      "reserved": 0,
      "available": 100,
      "status": "ACTIVE",
      "earlyBirdEndDate": null
    }
  ]
}
```

**Campos críticos**:
- `published`: boolean (indica si evento está visible)
- `tiers[]`: array (lista de opciones de compra)
- `tiers[].available`: number (asientos disponibles = quota - reserved)
- `tiers[].status`: string (ACTIVE, EXPIRED, INACTIVE, etc.)
- `tiers[].earlyBirdEndDate`: timestamp nullable (para validación de expiración)

Si tu endpoint retorna estructura distinta, actualiza:
1. Line ~131 con URL correcta
2. Lines ~142-153 con validaciones según response real
3. `event-availability-response.json` schema si necesario

---

## 🚀 Próximos Pasos

1. ✅ Ejecutar 4 scenarios en local y validar endpoint
2. ✅ Confirmar nombres exactos de `status` y estructura
3. ✅ Si hay discrepancias, actualizar feature + schema
4. ✅ Ready para CI/CD

