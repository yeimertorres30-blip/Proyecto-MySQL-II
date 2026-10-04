# Sistema de Gestión de Coworking y Oficinas Compartidas (`coworking_db`)

**Grupo 03**  
**Integrantes:**
- Exneider Nava
- Yeimer Torres
- Alvaro Angarita
- Hamilton Quiroga
- Carlos Perez

---

## 1. Descripción del Proyecto

Este proyecto consiste en el diseño, modelado e implementación de una base de datos relacional robusta y escalable en **MySQL 8.0+** para administrar las operaciones integrales de un centro de coworking moderno. 

El sistema (`coworking_db`) permite gestionar de manera centralizada:
- **Usuarios y Empresas:** Registro de clientes independientes y afiliados a planes corporativos.
- **Membresías:** Administración de planes (Diaria, Mensual, Corporativa, Premium) y control de estados (Activa, Suspendida, Vencida).
- **Espacios y Reservas:** Gestión de escritorios flexibles, oficinas privadas, salas de reuniones y auditorios, con validación de horarios y capacidades.
- **Servicios Adicionales:** Contratación de internet dedicado, parqueadero, lockers, barra de café e impresiones.
- **Facturación y Pagos:** Emisión de facturas, desglose de detalles, control de saldos pendientes, recaudos por múltiples métodos de pago y recargos por mora.
- **Control de Acceso:** Registro automatizado de ingresos y salidas mediante códigos QR o tarjetas RFID.
- **Auditoría y Automatización:** Trazabilidad de operaciones mediante triggers, funciones, procedimientos almacenados y eventos temporales.

---

## 2. Requisitos del Sistema

Para desplegar y ejecutar este proyecto se requiere:
- **Motor de Base de Datos:** MySQL Server versión 8.0 o superior (con soporte para roles nativos y Event Scheduler).
- **Cliente de Administración:** MySQL Workbench, DBeaver o cliente CLI de MySQL.
- **Control de Versiones:** Git y cuenta de GitHub.

---

## 3. Estructura del Repositorio

El repositorio sigue la convención de organización estandarizada del proyecto:

```text
coworking-mysql2-grupo03/
├── README.md
├── docs/
│   ├── modelo_logico.png
│   └── modelo_ER.md
└── sql/
    ├── 00_ddl/
    │   └── 01_estructura.sql
    ├── 01_dml/
    │   └── 01_datos_iniciales.sql
    ├── 02_consultas/
    │   ├── 01_usuarios_membresias.sql
    │   ├── 02_espacios_reservas.sql
    │   ├── 03_pagos_facturacion.sql
    │   ├── 04_accesos_asistencias.sql
    │   └── 05_consultas_avanzadas.sql
    ├── 03_funciones/
    │   └── 01_funciones.sql
    ├── 04_procedimientos/
    │   └── 01_procedimientos.sql
    ├── 05_triggers/
    │   └── 01_triggers.sql
    ├── 06_eventos/
    │   └── 01_eventos.sql
    └── 07_seguridad/
        ├── 01_roles.sql
        ├── 02_permisos.sql
        └── 03_usuarios.sql
```

---

## 4. Instalación y Configuración

Siga las instrucciones en orden secuencial para la correcta creación y población del sistema:

1. **Creación de la Estructura (DDL):**
   Ejecute el archivo `sql/00_ddl/01_estructura.sql` para crear la base de datos `coworking_db`, sus 17 tablas, claves primarias, foráneas, restricciones de chequeo e índices de rendimiento.

2. **Carga de Datos Iniciales (DML):**
   Ejecute `sql/01_dml/01_datos_iniciales.sql` para poblar la base de datos con registros multianuales de prueba (2022-2026).

3. **Carga de Funciones Stored:**
   Ejecute `sql/03_funciones/01_funciones.sql` para instalar las 20 funciones almacenadas analíticas y de validación.

4. **Carga de Procedimientos Almacenados:**
   Ejecute `sql/04_procedimientos/01_procedimientos.sql` para crear los 20 procedimientos de gestión transaccional.

5. **Activación de Triggers:**
   Ejecute `sql/05_triggers/01_triggers.sql` para activar las 20 reglas automáticas de integridad y auditoría.

6. **Programación de Eventos (Event Scheduler):**
   Ejecute `sql/06_eventos/01_eventos.sql` para habilitar el motor de eventos automáticos de tiempo.

7. **Configuración de Seguridad y Roles:**
   Ejecute en orden los archivos de la carpeta `sql/07_seguridad/`:
   - `01_roles.sql` (Creación de los 5 roles del sistema)
   - `02_permisos.sql` (Asignación granular de privilegios DML/DDL/EXECUTE)
   - `03_usuarios.sql` (Creación de cuentas de aplicación y asignación de roles)

8. **Ejecución de Consultas:**
   Los scripts dentro de `sql/02_consultas/` contienen las 100 consultas SQL organizadas por módulos de negocio.

---

## 5. Estructura de la Base de Datos

La base de datos consta de 17 tablas normalizadas hasta Tercera Forma Normal (3FN):

- `empresa`: Empresas asociadas para planes corporativos.
- `usuario`: Clientes registrados, empleados corporativos e independientes.
- `tipo_membresia`: Catálogo de membresías y precios base.
- `membresia`: Contratos de membresía asignados a los usuarios.
- `tipo_espacio`: Categorías de áreas de trabajo.
- `espacio`: Registro de escritorios, oficinas privadas, salas y auditorios.
- `horario_espacio`: Horarios de operación semanal por espacio.
- `reserva`: Solicitudes y agenda de espacios reservables.
- `reembolso_penalizacion`: Registros financieros por cancelaciones o penalizaciones.
- `servicio_adicional`: Catálogo de servicios complementarios.
- `reserva_servicio`: Servicios incluidos en reservas de espacios.
- `usuario_servicio`: Servicios contratados directamente por el usuario.
- `factura`: Documentos de cobro emitidos.
- `detalle_factura`: Desglose comercial línea a línea de cada factura.
- `pago`: Registro de transacciones monetarias recibidas.
- `control_acceso`: Registro de entradas/salidas mediante QR o RFID.
- `log_auditoria`: Bitácora centralizada de eventos, cambios y seguridad.

---

## 6. Módulos de Código Programable

### Funciones SQL (`fn_` - 20 Funciones)
Proporcionan cálculos rápidos y reutilizables, tales como:
- `fn_membresia_activa(p_id_usuario)`: Retorna si un usuario tiene un plan vigente.
- `fn_dias_restantes_membresia(p_id_usuario)`: Calcula los días restantes de contrato.
- `fn_horas_reservadas_mes(p_id_usuario, p_mes, p_año)`: Suma de horas reservadas en el mes.
- `fn_ingresos_mensuales_totales(p_mes, p_año)`: Total recaudado en un mes específico.
- `fn_usuario_mas_frecuente_mes(p_mes, p_año)`: Identifica al usuario con mayor asistencia.

### Procedimientos Almacenados (`sp_` - 20 Procedimientos)
Encapsulan lógica transaccional y reglas de negocio complejas:
- `sp_registrar_usuario`: Registro validado de clientes con generación de credenciales QR/RFID.
- `sp_crear_reserva`: Agendamiento con validación de horarios, solapamiento y capacidad.
- `sp_generar_factura` y `sp_registrar_pago`: Gestión de ciclo de cobros y saldos.
- `sp_registrar_ingreso` y `sp_registrar_salida`: Control de acceso físico en tiempo real.
- `sp_reporte_consolidado_usuario`: Resumen ejecutivo integral por usuario.

### Triggers (`trg_` - 20 Disparadores)
Garantizan la integridad y automatizan tareas inmediatas:
- Validar mayoría de edad en registro de usuarios (>= 18 años).
- Impedir reservas dobles sobre un mismo espacio en horarios cruzados.
- Asignar precios unitarios del catálogo automáticamente.
- Actualizar el saldo pendiente y cambiar estado de facturas a 'pagada' tras un cobro.
- Registrar cambios críticos en `log_auditoria`.

### Eventos Programados (`evt_` - 20 Eventos)
Ejecutan tareas periódicas en segundo plano:
- Actualización diaria de membresías vencidas a estado 'vencida'.
- Aplicación de recargos automáticos del 5% a facturas con mora.
- Cierre diario de caja y generación de reportes mensuales.
- Cierre automático de accesos sin marcación de salida al finalizar la jornada.
- Depuración periódica de logs antiguos.

---

## 7. Seguridad y Roles de Usuario

El sistema aplica el **Principio de Mínimo Privilegio** mediante 5 roles bien definidos:

1. **`rol_admin_coworking` (`admin_coworking`):**
   Acceso total DDL, DML y DCL sobre el esquema y gestión del servidor.
2. **`rol_recepcion` (`recepcionista`):**
   Permisos operativos para registro de usuarios, creación de reservas, check-in/check-out de accesos y lectura de facturación.
3. **`rol_usuario` (`usuario_app`):**
   Acceso orientado al autoservicio para consultar catálogos, agendar reservas propias y consultar sus facturas.
4. **`rol_gerente_corporativo` (`gerente_corporativo`):**
   Gestión de empleados de su empresa y consulta de facturación consolidada.
5. **`rol_contador` (`contador`):**
   Control total sobre facturación, registro de pagos, descuentos y reportes financieros.

---
