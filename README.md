<div align="center">
  
# 🚀 TICKETING_MVP_FUNCTIONAL_TEST

### Taller Semana 7: Expectativa vs. Realidad - Ejecución Ágil, MVP y Estrategia de Pruebas

**Rol / Líder QA:** Christopher Ismael Pallo Arias  
**Proyecto:** Construcción del Ticketing MVP real y su Certificación por Micro-Sprints (Fase Funcional - Karate)  
**Objetivo:** Vivir "el choque con la realidad" y certificar como QA el MVP funcional construido por DEV. Asegurar mediante BDD y aserciones estrictas que la lógica de negocio, reglas de dominio e integraciones de bases de datos operen sin fisuras.

<br />

### 🛠️ Technology Stack

**Functional API Testing Framework**
<br />
<img src="https://img.shields.io/badge/Karate-1.5.0-black?style=for-the-badge&logo=karate" alt="Karate DSL" />
<img src="https://img.shields.io/badge/Java-ED8B00?style=for-the-badge&logo=openjdk&logoColor=white" alt="Java" />
<img src="https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white" alt="PostgreSQL" />
<br />
<a href="https://skillicons.dev">
  <img src="https://skillicons.dev/icons?i=java,postgres,github" alt="Automation Stack" />
</a>

</div>

---

## 📌 Panel de Entrega y Resultados Formales

> ⚠️ **ATENCIÓN EVALUADOR:** Todos los insumos obligatorios exigidos sobre la validación funcional, flujos transaccionales y matrices de prueba están consolidados y listos para su auditoría:
> 
> 🔗 **[👉 HAZ CLIC AQUÍ PARA VER EL REPORTE OFICIAL DE KARATE EN LÍNEA](https://christopherpalloarias.github.io/TICKETING_SEM7_KARATE/)**
> *(Dashboard interactivo de Karate UI Report desplegado vía GitHub Pages)*

- 📄 **Test Plan Oficial:** [`TEST_PLAN.md`](./TEST_PLAN.md) *(Estrategia general documentada).*
- 📋 **Matriz de Test Cases:** [`TEST_CASES.md`](./TEST_CASES.md) *(Mapeo de requerimientos).*
- 📊 **Evidencia de Ejecución:** Revisar el dashboard en línea o la carpeta [`target/karate-reports/`](./target/karate-reports/).
- 🚀 **Features Implementados:** Consultar la carpeta [`src/test/java/api/`](./src/test/java/api/)

---

## 📋 Tabla de Contenidos
1. [Contexto del Proyecto: El Choque con la Realidad](#-contexto-del-proyecto-el-choque-con-la-realidad)
2. [A Vista de Pájaro (Cobertura)](#-a-vista-de-pájaro)
3. [Instrucciones de Clonado y Setup](#-instrucciones-de-clonado-y-setup)
4. [Ejecución de las Pruebas](#-ejecución-de-las-pruebas)
5. [Estructura de Archivos y Escenarios (Specs)](#-estructura-de-archivos-y-escenarios)
6. [Sobre la Orquestación ASDD](#-sobre-la-orquestación-asdd)

---

## 🎯 Contexto del Proyecto: El Choque con la Realidad

Este repositorio corresponde a la certificación funcional (**Karate DSL**) dentro de la **Fase 3: Estrategia de Calidad** exigida para el Taller 7. Tras diseñar la utopía en la Semana 6, nuestro objetivo de equipo fue construir y testear las piezas críticas seleccionadas del Backlog para entregar un **MVP funcional y valioso**.

Mientras DEV implementaba y lidiaba con la curva real de los Story Points mediante *micro-sprints* iterativos de 2 días, desde el rol de QA se redactó e impuso la arquitectura formal de calidad (`TEST_PLAN.md` y `TEST_CASES.md`).

Para asegurar que nuestro MVP cumpla estructuralmente con los flujos de negocio e integridad de base de datos prometidos, la Estrategia de Calidad implementó Validaciones Multi-Capa con Karate sobre:

1. **Flujo Feliz:** Generación de Entradas (Compra aprobada).
2. **Flujo Negativo:** Rechazo de pagos (HTTP 400).
3. **Flujo Asíncrono Complejo:** Expiración de reservas sin pagar, liberación de inventario y validación parametrizada vía base de datos (PostgreSQL + JDBC).

---

## 📊 A Vista de Pájaro

```
┌──────────────────────────────────────────────────────┐
│         TICKETING MVP — Karate Automation           │
├──────────────────────────────────────────────────────┤
│                                                      │
│  SPEC-001          SPEC-002          SPEC-003       │
│  Approved ✅       Rejected ✅       Expiration ✅   │
│  Purchase          Payment           & Release       │
│                                                      │
│  Happy Path        Negative Path     Async Path      │
│  Happy Path        Negative Path     + SQL Valid.    │
│                                      + 4-Layer Check │
│                                                      │
└──────────────────────────────────────────────────────┘

    ✅ 3 Specs (APPROVED)
    ✅ 3 Features (Operational)
    ✅ 12 Payloads/Schemas (Reusable)
    ✅ 1 SQL Helper (JDBC-based)
    ✅ Ready for CI/CD
```

---

## ⚡ Instrucciones de Clonado y Setup

> ⚠️ **Crítico:** Las pruebas funcionales exigen que la infraestructura objetivo (el clúster de microservicios) esté aprovisionada mediante `docker-compose` desde el repositorio principal de código de DEV.

### 1. Prerrequisitos
- El clúster backend (`TICKETING_SEM7`) ejecutándose en vivo.
- API Gateway activo en el puerto `8080`, `ms-events` en `8081` y `ms-ticketing` en `8082`.
- PostgreSQL expuesto en puertos `5434` (ticketing_db) y `5433` (events_db) para el `SPEC-003`.
- **Maven 3.6+** y Java JDK 17+ instalados.

### 2. Preparar el Entorno Karate

```bash
git clone https://github.com/ChristopherPalloArias/TICKETING_SEM7_KARATE.git
cd TICKETING_SEM7_KARATE

# Instalar dependencias puras (sin compilar el target aún)
mvn clean install -DskipTests
```

---

## 🧪 Ejecución de las Pruebas

Para ejecutar las pruebas apuntando a los recursos locales y con paso de variables de acceso de base de datos (vital para el helper JDBC en SPEC-003):

```bash
# Correr todo el Suite Master
mvn test

# Correr flujo específico (Ejemplo: Flujo Aprobado)
mvn test -Dtest=PurchaseApprovedFlowTest \
  -DbaseUrlEvents=http://localhost:8081 \
  -DbaseUrlTicketing=http://localhost:8082

# Correr flujo asíncrono avanzado con validación SQL
mvn test -Dtest=ExpirationReleaseFlowTest \
  -DbaseUrlEvents=http://localhost:8081 \
  -DbaseUrlTicketing=http://localhost:8082
```

> **Aviso de Compilación Temporal:** Tras correr el comando `mvn test`, Maven generará automáticamente el grandioso reporte html de Karate bajo la ruta `/target/karate-reports/karate-summary.html`.

---

## 📁 Estructura de Archivos y Escenarios

El framework emula un ecosistema Enterprise robusto mediante inyección de Payloads compartidos y Asserts estrictos de Schemas:

* **`src/test/java/api/purchase-approved-flow/`**: Valida respuesta segura `HTTP 201`, contratos JSON idénticos e integración exitosa con Payment Gateway.
* **`src/test/java/api/rejected-payment-flow/`**: Fuerza un payload adverso (DECLINED state) validando que el microservicio de Ticketing intercepte el error devolviendo `HTTP 400`.
* **`src/test/java/api/expiration-release-flow/`**: El flujo estrella. Inicia una reserva temporal, inyecta falla de pago, espera asíncronamente el proceso de background (Scheduler) y valida directamente sobre la Base de Datos PostgreSQL que el `Status` cambie a `EXPIRED` y que los asientos `quota` se hayan restaurado al pool público usando queries JDBC limpias.
* **`src/test/java/common/`**: Hospeda centralizadamente todos los Payloads (Json) de solicitud, contratos Schema (Json) de respuesta y los utilitarios `db-helper.feature` SQL.

---

## 🤖 Sobre la Orquestación ASDD

Gran parte del diseño arquitectónico de estas validaciones fue guiado por la metodología estructurada **Agent Spec Software Development (ASDD)**.
Para más detalle documental sobre las bitácoras o el pipeline de aprobación de estos Specs en Karate, revisa los archivos internos como [`BITACORA-IMPLEMENTACION.md`](./BITACORA-IMPLEMENTACION.md) o [`INDICE-DOCUMENTACION.md`](./INDICE-DOCUMENTACION.md).
