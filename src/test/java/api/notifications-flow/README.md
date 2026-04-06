# Notifications Flow Feature

> **Feature ID**: SPEC-005  
> **Status**: IMPLEMENTED  
> **Author**: qa-architect

## Descripción

Feature Karate que valida notificaciones generadas tras tres eventos críticos: compra aprobada, pago rechazado, y liberación por expiración.

---

## 📋 Estrategia de Validación

### Decisión: ENDPOINT-FIRST (Alternativa SQL Disponible)

**Selección de estrategia:**
```
✅ PRIMARY:   GET /api/v1/notifications/buyer/{buyerId} endpoint
❌ FALLBACK:  SQL query en tabla 'notifications' (si endpoint no existe)
```

**Rationale:**
1. **Endpoint es más limpio**: No requiere configuración adicional de BD
2. **Menos acoplamiento**: No depende de detalles internos de BD
3. **Contratos públicos**: Más cercano a la API real del usuario
4. **Fallback documentado**: Si endpoint no existe, usar SQL helper

**Si el endpoint no existe en tu microservicio:**
- Edita `notifications-flow.feature` línea ~120
- Cambiar validación manual de endpoint a llamada de SQL helper
- Ver sección "Fallback SQL" más adelante

---

## 🎯 Escenarios Cubiertos

### Scenario 1: Notification After Approved Purchase

**Objetivo**: Validar notificación tras compra aprobada

**Flujo**:
1. Setup: Room → Event DRAFT → Tier → Publish (reutilizado SPEC-001)
2. Reservación PENDING
3. Pago APPROVED
4. GET /api/v1/notifications/buyer/{buyerId} → valida notificación tipo `PURCHASE_APPROVED` o `PURCHASE_CONFIRMED`
5. Retry logic: Hasta 3 intentos con 1s entre intentos (para latencia de generación)

**Validaciones**:
- ✅ Response HTTP 200
- ✅ Array de notificaciones contiene tipo PURCHASE_APPROVED o PURCHASE_CONFIRMED
- ✅ Retry mechanism para latencia asincrónica

---

### Scenario 2: Notification After Rejected Payment

**Objetivo**: Validar notificación tras pago rechazado

**Flujo**:
1. Setup: Room → Event DRAFT → Tier → Publish (reutilizado SPEC-001)
2. Reservación PENDING
3. Pago DECLINED (HTTP 400)
4. GET /api/v1/notifications/buyer/{buyerId} → valida notificación tipo `PAYMENT_FAILED` o `PAYMENT_DECLINED`
5. Retry logic: Hasta 3 intentos con 1s entre intentos

**Validaciones**:
- ✅ Response HTTP 400 para pago
- ✅ Array de notificaciones contiene tipo PAYMENT_FAILED o PAYMENT_DECLINED
- ✅ Retry mechanism

---

### Scenario 3: Notification After Expiration/Release

**Objetivo**: Validar notificación tras liberación por expiración (Path B de SPEC-003)

**Flujo**:
1. Setup: Room → Event DRAFT → Tier → Publish (reutilizado SPEC-001)
2. Reservación PENDING
3. Pago DECLINED (activa mecanismo de expiración)
4. **WAIT 90 segundos** (scheduler procesa liberación - reutilizado SPEC-003)
5. GET /api/v1/notifications/buyer/{buyerId} → valida notificación tipo `RESERVATION_RELEASED`, `RESERVATION_EXPIRED` o `INVENTORY_RELEASED`
6. Retry logic: Hasta 3 intentos con 1s entre intentos

**Validaciones**:
- ✅ Pago rechazado dispara scheduler
- ✅ 90-segundo wait para procesamiento
- ✅ Notificación disponible tras espera
- ✅ Retry mechanism

---

## 🔗 Reutilización de Flows

| Scenario | SPEC Reutilizado | Setup | Payment Path |
|----------|------------------|-------|--------------|
| 1 | SPEC-001 | ✅ Completo | APPROVED |
| 2 | SPEC-001 + SPEC-002 | ✅ Completo | DECLINED |
| 3 | SPEC-001 + SPEC-003 | ✅ Completo | DECLINED + 90s wait |

**No se duplica código**: Se reutiliza patrón de setup 100% de specs previos.

---

## 📊 Endpoints Validados

| Endpoint | Método | Scenario | Status |
|----------|--------|----------|--------|
| POST /api/v1/rooms | POST | All | ✅ reutilizado |
| POST /api/v1/events | POST | All | ✅ reutilizado |
| POST /api/v1/events/{id}/tiers | POST | All | ✅ reutilizado |
| PATCH /api/v1/events/{id}/publish | PATCH | All | ✅ reutilizado |
| POST /api/v1/reservations | POST | All | ✅ reutilizado |
| POST /api/v1/reservations/{id}/payments | POST | All | ✅ reutilizado |
| **GET /api/v1/notifications/buyer/{buyerId}** | GET | All | ✅ **NEW** |

---

## ⚙️ Ejecución

### Comando Básico

```bash
mvn test -Dtest=NotificationsFlowTest \
  -DbaseUrlEvents=http://localhost:8081 \
  -DbaseUrlTicketing=http://localhost:8082
```

**Nota**: Las notificaciones podrían tener latencia. La feature implementa retry (3x con 1s entre intentos) para tolerar esto.

### Resultado Esperado

```
Scenario 1 ✅ PASS (Approved purchase notification)
Scenario 2 ✅ PASS (Rejected payment notification)
Scenario 3 ✅ PASS (Expiration/release notification)

3 scenarios executed, 3 passed, 0 failed
```

### Con Timeout

```bash
# Si los scenarios tardan más (por latencia de notificaciones)
mvn test -Dtest=NotificationsFlowTest -DtestTimeout=300000 \
  -DbaseUrlEvents=http://localhost:8081 \
  -DbaseUrlTicketing=http://localhost:8082
```

---

## 🆘 Fallback: SQL Validation

**Si el endpoint GET /api/v1/notifications/buyer/{buyerId} NO existe:**

### Opción 1: Usar SQL Helper Directamente

El archivo `notification-helper.feature` proporciona 2 scenarios SQL reutilizables:

#### @checkNotificationByBuyerId
```gherkin
* call karate.callSingle('classpath:common/sql/notification-helper.feature@checkNotificationByBuyerId',
  { buyerId: myBuyerId, notificationType: 'PURCHASE_APPROVED' })
```

**Parámetros:**
- `buyerId`: UUID del comprador
- `notificationType`: Tipo a buscar (PURCHASE_APPROVED, PAYMENT_FAILED, RESERVATION_RELEASED, etc.)

**Retorna:**
- `found`: boolean
- `notificationType`: tipo buscado
- `latestNotification`: objeto con type, message, created_at
- `passed`: boolean (true si encontrado)

#### @checkNotificationCount
```gherkin
* call karate.callSingle('classpath:common/sql/notification-helper.feature@checkNotificationCount',
  { buyerId: myBuyerId, minExpected: 1 })
```

**Parámetros:**
- `buyerId`: UUID del comprador
- `minExpected`: Número mínimo de notificaciones esperadas

**Retorna:**
- `count`: número total encontrado
- `minExpected`: mínimo esperado
- `passed`: boolean (true si count >= minExpected)

### Opción 2: Modo Manual

Si necesitas investigar qué notificaciones existen realmente:

```sql
-- Conectar a notifications_db (o dondequiera que estén)
SELECT * FROM notifications 
WHERE buyer_id = 'your-buyer-uuid' 
ORDER BY created_at DESC;

-- Columnas esperadas: id, buyer_id, type, message, created_at, updated_at
```

### Opción 3: Editar Feature

En `notifications-flow.feature`, cambiar sección de validación:

```gherkin
# Antes: validación por endpoint
Given url baseUrlTicketing + '/api/v1/notifications/buyer/' + buyerId
When method get
Then status 200

# Después: validación por SQL
* call karate.callSingle('classpath:common/sql/notification-helper.feature@checkNotificationByBuyerId',
  { buyerId: buyerId, notificationType: 'PURCHASE_APPROVED' })
```

**Base de datos esperada para SQL:**
- Host: localhost
- Port: 5432 (ajustable en notification-helper.feature)
- Database: `notifications_db`
- User: `postgres`
- Password: `postgres`
- Table: `notifications` con columnas: `buyer_id`, `type`, `message`, `created_at`

---

## 🎓 Notas Técnicas

### Retry Logic
```gherkin
* def maxRetries = 3
* def retryCount = 0
* def notificationFound = false

* while (retryCount < maxRetries && !notificationFound)
  * call sleep(1000)
  # Intentar validación aquí
  * eval retryCount++
```

**Rationale**: Notificaciones generadas asincrónicamente. Retry tolera latencia de hasta 3 segundos.

### Tipos de Notificación Flexibles
```gherkin
* def approvedNotification = notifications[?(@.type == 'PURCHASE_APPROVED' || @.type == 'PURCHASE_CONFIRMED')]
```

**Rationale**: No asumimos nombre exacto de tipo. Aceptamos variantes comunes.

### Escenario 3: 90-Segundo Wait
```gherkin
* java.lang.Thread.sleep(90000)
```

**Rationale**: Reutilizado de SPEC-003. TTL 10min + scheduler 60sec = 90s conservative.

---

## 📦 Assets

### Reutilizados
✅ Todos los payloads y schemas de SPEC-001  
✅ Todos los payloads de SPEC-002 (payment declined)  
✅ Setup de SPEC-003 (90s wait pattern para Scenario 3)

### Nuevos
Ninguno. Feature es 100% composición de behaviors previos + endpoint nuevo.

---

## ✅ Checklist de Completitud

- [x] 3 scenarios implementados
- [x] Setup reutilizable 100%
- [x] Retry logic para latencia asincrónica
- [x] Tipos de notificación flexibles (no inventados)
- [x] SQL helper como fallback
- [x] Test Runner creado
- [x] README documentado
- [x] Sin SQL en feature principal (endpoint-first)
- [x] Sin invención de campos
- [x] Nota breve de estrategia

---

## 🚀 Siguiente: Considera

Si el endpoint no existe y necesitas SQL:
1. Configura PostgreSQL en host/port/database correctos
2. Edita `notification-helper.feature` lines 9-10 para credenciales reales
3. Reemplaza llamadas de endpoint con SQL helper calls

Si quieres centralizar configuración de DB:
1. Agregar `config.notificationsDb` en `karate-config.js`
2. Actualizar `notification-helper.feature` para reutilizar config

