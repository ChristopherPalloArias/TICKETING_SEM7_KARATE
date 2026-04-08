<div align="center">
  
# 🚀 TICKETING_MVP_FUNCTIONAL_TEST

### Taller Semana 7: Expectativa vs. Realidad - Ejecución Ágil, MVP y Estrategia de Pruebas

**Rol / Líder QA:** Christopher Ismael Pallo Arias  
**Proyecto:** Construcción del Ticketing MVP real y su Certificación por Micro-Sprints (Fase Funcional - Karate)  
**Objetivo:** Vivir "el choque con la realidad" y certificar como QA el MVP funcional construido por DEV. Asegurar mediante BDD y aserciones estrictas que la lógica de negocio, reglas de dominio e integraciones de bases de datos operen sin fisuras según la priorización de riesgos documentada (`TEST_PLAN.md`).

<br />

### 🛠️ Technology Stack

**Functional API Testing Framework**
<br />
<img src="https://img.shields.io/badge/Karate-1.5.0-black?style=for-the-badge&logo=karate" alt="Karate DSL" />
<img src="https://img.shields.io/badge/Java-ED8B00?style=for-the-badge&logo=openjdk&logoColor=white" alt="Java" />
<img src="https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white" alt="PostgreSQL" />
<img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker" />
<br />
<a href="https://skillicons.dev">
  <img src="https://skillicons.dev/icons?i=java,postgres,github,docker" alt="Automation Stack" />
</a>

</div>

---

## 📌 Panel de Entrega y Resultados Formales

> ⚠️ **ATENCIÓN EVALUADOR:** Todos los insumos obligatorios exigidos sobre la validación funcional, flujos transaccionales y matrices de prueba están consolidados y listos para su auditoría:
> 
> 🔗 **[👉 HAZ CLIC AQUÍ PARA VER EL INFORME OFICIAL DE LOS RESULTADOS (KARATE)](https://christopherpalloarias.github.io/TICKETING_SEM7_KARATE/)**

- 📄 **Test Plan Oficial:** [`TEST_PLAN.md`](https://github.com/ChristopherPalloArias/PRD_BACKLOG/blob/main/TEST_PLAN.md) *(Estrategia general documentada y riesgos).*
- 📋 **Matriz de Test Cases:** [`TEST_CASES.md`](https://github.com/ChristopherPalloArias/PRD_BACKLOG/blob/main/TEST_CASES.md) *(Mapeo explícito de métricas, CA y casos evaluados).*
- 📊 **Evidencia de Ejecución:** El enlace web contiene el Dashboard o revisa la carpeta local `docs/karate-reports/`.
- 🚀 **Scripts de Escenarios:** Consultar la carpeta [`src/test/java/api/`](./src/test/java/api/)

---

## 📋 Tabla de Contenidos
1. [Contexto del Proyecto: El Choque con la Realidad](#-contexto-del-proyecto-el-choque-con-la-realidad)
2. [Arquitectura y Estructura del Framework](#️-arquitectura-y-estructura-del-framework)
3. [Instrucciones de Clonado y Setup de Backend](#-instrucciones-de-clonado-y-setup-de-backend)
4. [Ejecución de las Pruebas](#️-ejecución-de-las-pruebas)
5. [Consideraciones Técnicas y Retos Avanzados Resueltos](#-consideraciones-técnicas-y-retos-avanzados-resueltos)
6. [Sobre la Orquestación ASDD](#-sobre-la-orquestación-asdd)

---

## 🎯 Contexto del Proyecto: El Choque con la Realidad

Este repositorio corresponde a la certificación funcional (**Karate DSL**) dentro de la **Fase 3: Estrategia de Calidad** exigida para el Taller 7. Tras diseñar la utopía en la Semana 6, nuestro objetivo de equipo fue construir y testear las piezas críticas seleccionadas del Backlog para entregar un **MVP funcional y valioso**.

Mientras DEV implementaba y lidiaba con la curva real de los Story Points mediante *micro-sprints* iterativos de 2 días, desde el rol de QA se redactó e impuso la arquitectura formal de calidad alojada centralmente en el repositorio de Producto (`PRD_BACKLOG`): [`TEST_PLAN.md`](https://github.com/ChristopherPalloArias/PRD_BACKLOG/blob/main/TEST_PLAN.md) y [`TEST_CASES.md`](https://github.com/ChristopherPalloArias/PRD_BACKLOG/blob/main/TEST_CASES.md). Toda la cobertura técnica que observarás en esta suite nace y obedece rígidamente a los escenarios definidos en dichas matrices.

Para asegurar que nuestro MVP cumpla estructuralmente con los flujos de negocio e integridad de base de datos prometidos, la Estrategia de Calidad implementó Validaciones Multi-Capa con Karate abarcando **totalidad del scope MVP**: 7 Historias de Usuario resueltas en 29 Casos de Prueba Críticos.

Entre lo más destacable evaluado:
- **Flujos Felices (Happy Paths):** Creación de Eventos, Tiers, y finalización de Compra (`HTTP 201`/`200`).
- **Flujos Negativos:** Rechazo de pagos (`HTTP 400`), sobreventas intentadas, precios inválidos.
- **Flujo Asíncrono Complejo:** Expiración de reservas después de 10 minutos simulados, con liberación de inventario y validación directa sobre la Base de Datos PostgreSQL.

---

## 🏗️ Arquitectura y Estructura del Framework

La automatización no es monolítica. Está dividida estratégicamente en **10 módulos (`features`)** que mapean la cobertura formal reportada en el Plan de Pruebas:

| Capa / Paquete (dentro de `src/test/java/api/`) | Historia(s) Cubierta(s) | Comportamiento Validado |
|---|---|---|
| 📦 **`event-and-tier-happy-path/`** | `HU-01, HU-02` | Test de creación base de eventos, aforo, y configuración de los tres tiers de precios permitidos. |
| 🛡️ **`event-validation-negative/`** | `HU-01` | Validación estricta de bordes: campos faltantes, fechas erróneas, o aforos que violan la limitación de la sala. |
| 🛑 **`tier-validation-negative-and-earlybird/`** | `HU-02` | Intento de suma de cupos errónea, valores negativos e incursión de fechas inválidas para Early Birds. |
| 👁️ **`event-availability-visibility/`** | `HU-03` | Lectura de disponibilidad visible, ocultamiento de *Early Bird* cuando expira el tiempo. |
| ✅ **`purchase-approved-flow/`** | `HU-04` | Integración con Payment Gateway aprobado. Disminución correcta del inventario y emisión del Ticket. |
| ❌ **`rejected-payment-flow/`** | `HU-04` | Respuesta adversa de pasarela (`DECLINED`), recepción de `HTTP 400` y prevención de emisión de Ticket. |
| ⚔️ **`reservation-advanced-lifecycle/`** | `HU-04` | Protección estricta de inventario bajo ataques y transacciones simultáneas para la última entrada disponible. |
| ⏰ **`expiration-release-flow/`** | `HU-05` | Interacción asíncrona avanzada (Jobs). Expiración forzada y validación de reposición de `Quota` usando **JDBC Parametrizado**. |
| 📩 **`notifications-flow/`** | `HU-06` | Comprobación de que tras los cierres del ciclo de vida se despachen notificaciones vía RabbitMQ. |
| 🎫 **`ticket-visibility-and-access-control/`** | `HU-07` | Verificación de que un ticket está seguro (Auth headers) y de que los usuarios no acceden a los recursos de otros. |
| 🛠️ **`common/`** (Shared Schemas & Utils) | *Cross-cutting* | Todos los payloads compartidos (`event-request.json`), aserciones difusas Schema Validation (`ticket-response.json`) y el poderoso archivo `db-helper.feature` (Consultas SQL Reusables). |

---

## ⚡ Instrucciones de Clonado y Setup de Backend

> ⚠️ **Crítico:** Las pruebas funcionales interactúan a fondo con el servicio, por lo que presuponen que el API Gateway, la Base de Datos y los microservicios se encuentran sanos e inicializados localmente o en el lab.

### 1. Clonar y Levantar el Clúster Backend
El proyecto del backend y sus bases de datos operan mediante `docker-compose` en un repositorio hermano.

```bash
# Cambiarse a un directorio base
cd /alguna/ruta/local

# Clonar el ecosistema de Backend
git clone https://github.com/ChristopherPalloArias/TICKETING_SEM7.git
cd TICKETING_SEM7

# Configurar variables (PostgreSQL, RabbitMQ, etc)
cp .env.template .env
```
```bash
# Levantar de forma orquestada la topología
docker-compose up -d --build
```
*Asegúrate de que el API Gateway responde en el puerto `8080`, `ms-events` en `8081` y `ms-ticketing` en `8082`*.

---

### 2. Preparar el Entorno de Automatización Karate

```bash
# Desde otro terminal, clonar este repositorio Karate
git clone https://github.com/ChristopherPalloArias/TICKETING_SEM7_KARATE.git
cd TICKETING_SEM7_KARATE

# Instalar dependencias mediante Maven e inyectar el caché local
mvn clean install -DskipTests
```

---

## ▶️ Ejecución de las Pruebas

Al ejecutar las pruebas, se golpean directamente los microservicios.

### Prueba Master (Todas las Specs)
Corre la gran suite completa de 29 escenarios de negocio, incluyendo las verificaciones SQL (que utilizarán credenciales base expuestas para el lab `localhost:5433`).
```bash
mvn test
```

### Pruebas Específicas por Camino
Para diagnosticar módulos individuales, invocar a sus *Runners*. Ejemplo:
```bash
# Probar Únicamente el flujo de Reserva Expirada asíncrono
mvn test -Dtest=ExpirationReleaseFlowTest \
  -DbaseUrlEvents=http://localhost:8081 \
  -DbaseUrlTicketing=http://localhost:8082
```

> **Sobre el Autodespliegue del Reporte e Ignore:** Debido a que tradicionalmente la carpeta `target/karate-reports` está bloqueada por el `.gitignore`, hemos configurado una evasión trasladando manual o computacionalmente esos datos estáticos HTML nativos que arroja Maven hacia `docs/karate-reports/`. Nuestro pipeline `gh-pages.yml` recogerá esa carpeta y formará el reporte web oficial online.

---

## 🧩 Consideraciones Técnicas y Retos Avanzados Resueltos

* **Schema Validation Inteligente (Fuzzy Matchers):**  
  Karate fue explotado no solo para ver respuestas `HTTP 200`, sino para asercionar formalmente la forma de la respuesta (Contract Testing). Se forzaron validadores como `#uuid`, `#number`, e `#ignore` en la carpeta `common/schemas/` impidiendo que cualquier alteración oculta por parte del DEV rompa las aplicaciones móviles dependientes.

* **Validación Multi-Capa c/ Interconexión JDBC (SPEC-003):**  
  En el escenario de expiración de eventos (`HU-05`) un chequeo puramente HTTP se quedaba corto, pues la reserva mutaba asíncronamente (Scheduler del backend). Se desarrolló el asset utilitario `db-helper.feature` que, utilizando librerías JDBC sobreescritas para Java y variables globales en `karate-config.js`, se conecta crudo a PostgreSQL en puertos directos durante la ejecución, asercionando que el estado de DB pasó a `EXPIRED` y mitigando definitivamente la vulnerabilidad de sobreventas.

* **Time-Travel API sobre Entornos Mockificados:**  
  Para certificar el Timer de expiración de 10 minutos (HU-04), esperar activamente ralentizaría toda la integración continua. Se aplicaron endpoints de *Testability* del backend acordados para inyectar adelantos temporales (`/testability/clock/advance?minutes=15`), posibilitando correr en segundos lo que la carga cronometrada tardaría minutos.

## 🤖 Sobre la Orquestación ASDD

Para más detalle sobre las directrices de Calidad Preventiva impulsadas por Especificaciones controladas por Agente AI que enmarcan la evolución del proyecto, consulta las bitácoras internas documentales en [`.github/README_ASDD.md`](.github/README_ASDD.md) y los guiones `README_ASDD.md` dispersos en la arquitectura.
