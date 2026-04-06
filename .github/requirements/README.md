# Requirements — Requerimientos de Negocio

Esta carpeta aloja los requerimientos crudos recibidos en lenguaje natural (resolviendo los retos técnicos del cliente o features de un sprint), estructurados de forma formal para iniciar el flujo ASDD con Karate.

## ¿Qué hay en esta carpeta?

- **`README.md`**: Este manual operativo.
- **`requirement-template.md`**: El **MOLDE** oficial maestro de requerimientos técnicos para la arquitectura Karate. **No debe editarse**. Es el canon operativo.
- **Requerimientos Reales (ej: `client-api-crud-challenge.md`)**: Son copias del template, rellenados con el lenguaje natural estructurado del reto técnico en sí. Es aquí donde se resuelve el análisis humano o donde interviene la IA base.

## Flujo Operativo

Todo reto o feature en este framework debe inicializarse copiando la plantilla antes de que un agente lo convierta en Especificación Técnica (`.spec.md`):

1. **Recepción**: Recibes un PDF, correo o historia de usuario detallando el reto API REST.
2. **Plantillaje**: Copias íntegramente `requirement-template.md`, lo guardas en esta misma carpeta y lo bautizas con un nombre kebab-case (ej: `auth-flow-challenge.md` o `client-crud-api.md`).
3. **Escritura**: Traduces las exigencias del cliente a ese documento copiado cubriendo la tabla de *endpoints*, el contexto de autorización y la matriz de pruebas negativas.
4. **ASDD Entry**: Le pides al Agente ASDD que inicie el flujo usando ese archivo. `Copilot: /generate-spec auth-flow-challenge`.

> **Regla de Oro**: Jamás sobrescribas la plantilla `requirement-template.md`. Sirve como guía de robustez para prevenir ambigüedad y evitar omitir escenarios, URLs base y validaciones de esquema de datos.
