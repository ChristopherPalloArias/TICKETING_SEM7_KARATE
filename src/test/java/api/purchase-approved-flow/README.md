# Ticketing MVP - Approved Purchase Flow Automation

## Overview
This is a complete end-to-end Karate automation for the core happy path of the Ticketing MVP purchase flow, covering:
- Room creation (Setup step)
- Event creation (Technical note: internal DRAFT state)
- Tier configuration
- Event publication
- Reservation creation
- Payment processing with ticket generation

## Feature File
- **Location**: `src/test/java/api/purchase-approved-flow/purchase-approved-flow.feature`
- **Scenario**: HU-01, HU-02, HU-04 - Complete Approved Purchase Flow
- **Focus**: Happy path only, sequential dependencies

## Running the Tests

### Prerequisites
- Maven 3.6+
- JDK 11+
- Karate framework configured in pom.xml
- Local/Docker services running:
  - `ms-events` on default port (or via -DbaseUrlEvents)
  - `ms-ticketing` on default port (or via -DbaseUrlTicketing)

### Execution Options

#### Option 1: Default (Single Base URL)
```bash
mvn test -Dtest=PurchaseApprovedFlowTest -DbaseUrl=http://localhost:8080
```

#### Option 2: Separate Service URLs
```bash
mvn test -Dtest=PurchaseApprovedFlowTest \
  -DbaseUrlEvents=http://localhost:8081 \
  -DbaseUrlTicketing=http://localhost:8082
```

#### Option 3: Run All Tests
```bash
mvn test
```

### Assertions and Validation
The feature validates:
- **HTTP Status Codes**: 201 for creation, 200 for PATCH/successful operations
- **Happy Path Contracts**: Fuzzy matching for `#uuid`, `#string`, `#number`; strict matching for business values (`DRAFT`, `PUBLISHED`, `PENDING`, `CONFIRMED`)
- **Data Flow**: IDs extracted at each step and passed to subsequent requests
- **Ticket Generation**: Verified in final payment response

### Test Data
- **Generated Dynamically** at runtime:
  - `buyerId`: Timestamp-based unique identifier
  - `buyerEmail`: Derived from `buyerId`
  - `eventTitle`: Timestamp-based unique identifier
  - `X-User-Id`: Reused between reservation and payment (same value)
- **No SQL or database setup required**

### Assets Used
- **Payloads** (templates): `src/test/java/common/payloads/`
  - `room-create-request.json`
  - `event-create-request.json`
  - `tiers-create-request.json`
  - `reservation-create-request.json`
  - `payment-request.json`

- **Schemas** (response validation): `src/test/java/common/schemas/`
  - `room-response.json`
  - `event-response.json`
  - `tiers-response.json`
  - `event-published-response.json`
  - `reservation-response.json`
  - `payment-response.json`

### Expected Output
```
Scenario: HU-01, HU-02, HU-04 - Complete Approved Purchase Flow
  HU-01: Creación de evento de obra de teatro (Setup: Sala) ✓
  HU-01: Creación de evento de obra de teatro (Setup: Evento) ✓
  HU-02: Configuración de tiers y precios por evento ✓
  HU-01: Creación de evento de obra de teatro (Publicar Evento) ✓
  HU-04: Reserva y compra de entrada con pago simulado (Creación de Reserva) ✓
  HU-04: Reserva y compra de entrada con pago simulado (Pago Aprobado) ✓
  
Purchase complete! Ticket generated: [uuid]
```

### Scope Limitations (Intentional)
This first implementation covers **happy path only**:
- ✓ Sequential setup (Room → Event → Tier → Publish → Reservation → Payment)
- ✓ Approved payment processing
- ✓ Ticket generation
- ✓ Admin and buyer authentication headers
- ✗ No negative scenarios
- ✗ No database setup/teardown (SQL)
- ✗ No seat selection (optional field not used)
- ✗ No async validation (RabbitMQ, scheduler)
- ✗ No expiration handling

### Troubleshooting
1. **Connection Refused**: Ensure services are running on correct ports
2. **401/403 Errors**: Verify `X-Role: ADMIN` and `X-User-Id` headers are sent correctly
3. **Schema Mismatch**: Check actual service response format against schemas in `common/schemas/`
4. **Field Names**: Verify field names in payloads match actual API contracts (e.g., `date` vs `eventDate`)

### Related Documentation
- **Specification**: `.github/specs/ticketing-karate-purchase-approved-flow.spec.md` (APPROVED v1.2)
- **Requirements**: `.github/requirements/ticketing-karate-purchase-approved-flow.md`
