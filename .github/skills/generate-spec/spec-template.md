---
id: SPEC-###
status: DRAFT
feature: nombre-del-feature
created: YYYY-MM-DD
updated: YYYY-MM-DD
author: spec-generator
version: "1.0"
related-specs: []
---

# Spec: [Nombre de la Funcionalidad]

> **Estado:** `DRAFT` → aprobar con `status: APPROVED` antes de iniciar implementación.
> **Ciclo de vida:** DRAFT → APPROVED → IN_PROGRESS → IMPLEMENTED → DEPRECATED

---

## 1. REQUERIMIENTOS

### Descripción
Resumen de la funcionalidad en 2-3 oraciones. Qué hace, para quién y qué problema resuelve.

### Requerimiento de Negocio
El requerimiento original tal como fue proporcionado por el usuario (o copiado de `.github/requirements/<feature>.md`).

### Historias de Usuario

#### HU-01: [Título descriptivo corto]

```
Como:        [rol del usuario — ej. Usuario autenticado, Administrador]
Quiero:      [acción o funcionalidad concreta]
Para:        [valor o beneficio esperado por el negocio]

Prioridad:   Alta / Media / Baja
Estimación:  XS / S / M / L / XL
Dependencias: HU-X, HU-Y o Ninguna
Capa:        API / Automatización
```

#### Criterios de Aceptación — HU-01

**Happy Path**
```gherkin
CRITERIO-1.1: [nombre del escenario exitoso]
  Dado que:  [contexto inicial válido]
  Cuando:    [acción del usuario]
  Entonces:  [resultado esperado verificable]
```

**Error Path**
```gherkin
CRITERIO-1.2: [nombre del escenario de error]
  Dado que:  [contexto inicial]
  Cuando:    [acción inválida o datos incorrectos]
  Entonces:  [manejo del error esperado con código HTTP y mensaje]
```

**Edge Case** *(si aplica)*
```gherkin
CRITERIO-1.3: [nombre del caso borde]
  Dado que:  [contexto de borde]
  Cuando:    [acción en el límite]
  Entonces:  [resultado esperado en el límite]
```

### Reglas de Negocio
1. Regla de validación (ej. "el campo X es obligatorio y no puede superar 100 caracteres")
2. Regla de autorización (ej. "solo el Administrador puede eliminar")
3. Regla de integridad (ej. "el nombre debe ser único en la colección")

---

## 2. DISEÑO API

### API Endpoints

#### POST /api/v1/[features]
- **Descripción**: Crea un nuevo recurso
- **Auth requerida**: sí / no
- **Request Body**:
  ```json
  { "name": "string", "description": "string (opcional)" }
  ```
- **Response 201**:
  ```json
  { "uid": "uuid", "name": "string", "created_at": "iso8601", "updated_at": "iso8601" }
  ```
- **Response 400**: campo obligatorio faltante o inválido
- **Response 401**: token ausente o expirado
- **Response 409**: ya existe un recurso con ese nombre

#### GET /api/v1/[features]
- **Descripción**: Lista todos los recursos
- **Auth requerida**: sí
- **Response 200**:
  ```json
  [{ "uid": "uuid", "name": "string", ... }]
  ```

#### GET /api/v1/[features]/{uid}
- **Descripción**: Obtiene un recurso por uid
- **Auth requerida**: sí
- **Response 200**: recurso completo
- **Response 404**: no encontrado

#### PUT /api/v1/[features]/{uid}
- **Descripción**: Actualiza un recurso existente
- **Auth requerida**: sí
- **Request Body**: campos opcionales a actualizar
- **Response 200**: recurso actualizado
- **Response 404**: no encontrado

#### DELETE /api/v1/[features]/{uid}
- **Descripción**: Elimina un recurso
- **Auth requerida**: sí
- **Response 204**: eliminado exitosamente
- **Response 404**: no encontrado

### Arquitectura y Dependencias
- Paquetes nuevos requeridos: ninguno / listar si aplica
- Servicios externos: listar integraciones (auth, storage, third-party APIs)
- Impacto en punto de entrada de la app: registrar router/módulo si aplica

### Notas de Implementación
> Observaciones técnicas, decisiones de diseño o advertencias para los agentes de desarrollo.

---

### 3. LISTA DE TAREAS

> Checklist accionable para la automatización en Karate. Marcar cada ítem (`[x]`) al completarlo.

### QA y Gherkin
- [ ] Ejecutar skill `/gherkin-case-generator` → escenarios CRITERIO-1.1, 1.2, 1.3
- [ ] Ejecutar skill `/risk-identifier` → clasificación ASD de riesgos

### Automatización Karate
- [ ] Crear archivo `.feature` para escenario feliz
- [ ] Incorporar aserciones precisas (código HTTP, campos mandatarios)
- [ ] Manejar creación y borrado de datasets de prueba (Setup/Teardown)
- [ ] Crear archivo `.feature` para validaciones negativas y de seguridad

### QA
- [ ] Ejecutar skill `/gherkin-case-generator` → criterios CRITERIO-1.1, 1.2, 1.3
- [ ] Ejecutar skill `/risk-identifier` → clasificación ASD de riesgos
- [ ] Revisar cobertura de tests contra criterios de aceptación
- [ ] Validar que todas las reglas de negocio están cubiertas
- [ ] Actualizar estado spec: `status: IMPLEMENTED`
