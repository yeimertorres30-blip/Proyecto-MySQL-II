# Roles, Permisos y Credenciales

## Proyecto: Gestión de Coworking y Oficinas Compartidas
## Grupo 03 — Exneider, Said, Alvaro, Hamilton, Yeimer

---

## Roles creados

| # | Rol | Descripción |
|---|-----|-------------|
| 1 | `rol_administrador` | Administrador del Coworking |
| 2 | `rol_recepcionista` | Recepcionista |
| 3 | `rol_usuario` | Usuario |
| 4 | `rol_gerente_corporativo` | Gerente Corporativo |
| 5 | `rol_contador` | Contador |

---

## Credenciales de los usuarios

| # | Rol | Usuario | Contraseña | Host |
|---|-----|---------|------------|------|
| 1 | Administrador | `admin_coworking` | `AdminCoworking2025!` | `localhost` y `%` |
| 2 | Recepcionista | `recepcionista` | `Recepcionista2025!` | `localhost` |
| 3 | Usuario | `usuario_app` | `UsuarioApp2025!` | `localhost` |
| 4 | Gerente Corporativo | `gerente_corporativo` | `GerenteCorp2025!` | `localhost` |
| 5 | Contador | `contador` | `Contador2025!` | `localhost` |

---

## Permisos por rol

### 1. `rol_administrador` — Administrador del Coworking

```sql
GRANT ALL PRIVILEGES ON coworking_db.* TO 'rol_administrador';
GRANT CREATE USER, RELOAD, PROCESS ON *.* TO 'rol_administrador';
```

**Permisos:** Acceso total a todas las tablas de `coworking_db` (SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, INDEX, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, EXECUTE, TRIGGER, EVENT, LOCK TABLES, REFERENCES, CREATE TEMPORARY TABLES) + privilegios globales de administración (CREATE USER, RELOAD, PROCESS).

---

### 2. `rol_recepcionista` — Recepcionista

| Tabla | SELECT | INSERT | UPDATE | DELETE |
|-------|:------:|:------:|:------:|:------:|
| `empresa` | ✅ | ✅ | ✅ | ❌ |
| `usuario` | ✅ | ✅ | ✅ | ❌ |
| `membresia` | ✅ | ✅ | ✅ | ❌ |
| `tipo_membresia` | ✅ | ❌ | ❌ | ❌ |
| `espacio` | ✅ | ✅ | ✅ | ❌ |
| `tipo_espacio` | ✅ | ❌ | ❌ | ❌ |
| `horario_espacio` | ✅ | ✅ | ✅ | ❌ |
| `reserva` | ✅ | ✅ | ✅ | ❌ |
| `reserva_servicio` | ✅ | ✅ | ✅ | ❌ |
| `servicio_adicional` | ✅ | ❌ | ❌ | ❌ |
| `usuario_servicio` | ✅ | ✅ | ✅ | ❌ |
| `control_acceso` | ✅ | ✅ | ✅ | ❌ |
| `reembolso_penalizacion` | ✅ | ✅ | ❌ | ❌ |
| `factura` | ✅ | ❌ | ❌ | ❌ |
| `detalle_factura` | ✅ | ❌ | ❌ | ❌ |
| `pago` | ✅ | ❌ | ❌ | ❌ |

---

### 3. `rol_usuario` — Usuario

| Tabla | SELECT | INSERT | UPDATE | DELETE |
|-------|:------:|:------:|:------:|:------:|
| `tipo_espacio` | ✅ | ❌ | ❌ | ❌ |
| `espacio` | ✅ | ❌ | ❌ | ❌ |
| `horario_espacio` | ✅ | ❌ | ❌ | ❌ |
| `tipo_membresia` | ✅ | ❌ | ❌ | ❌ |
| `servicio_adicional` | ✅ | ❌ | ❌ | ❌ |
| `reserva` | ✅ | ✅ | ✅ | ❌ |
| `reserva_servicio` | ✅ | ✅ | ✅ | ❌ |
| `usuario_servicio` | ✅ | ✅ | ❌ | ❌ |
| `membresia` | ✅ | ❌ | ❌ | ❌ |
| `control_acceso` | ✅ | ❌ | ❌ | ❌ |
| `factura` | ✅ | ❌ | ❌ | ❌ |
| `detalle_factura` | ✅ | ❌ | ❌ | ❌ |
| `pago` | ✅ | ❌ | ❌ | ❌ |
| `reembolso_penalizacion` | ✅ | ❌ | ❌ | ❌ |

---

### 4. `rol_gerente_corporativo` — Gerente Corporativo

| Tabla | SELECT | INSERT | UPDATE | DELETE |
|-------|:------:|:------:|:------:|:------:|
| `usuario` | ✅ | ✅ | ✅ | ❌ |
| `empresa` | ✅ | ❌ | ❌ | ❌ |
| `membresia` | ✅ | ✅ | ✅ | ❌ |
| `tipo_membresia` | ✅ | ❌ | ❌ | ❌ |
| `reserva` | ✅ | ❌ | ❌ | ❌ |
| `reserva_servicio` | ✅ | ❌ | ❌ | ❌ |
| `usuario_servicio` | ✅ | ❌ | ❌ | ❌ |
| `servicio_adicional` | ✅ | ❌ | ❌ | ❌ |
| `espacio` | ✅ | ❌ | ❌ | ❌ |
| `tipo_espacio` | ✅ | ❌ | ❌ | ❌ |
| `factura` | ✅ | ❌ | ❌ | ❌ |
| `detalle_factura` | ✅ | ❌ | ❌ | ❌ |
| `pago` | ✅ | ❌ | ❌ | ❌ |
| `reembolso_penalizacion` | ✅ | ❌ | ❌ | ❌ |
| `control_acceso` | ✅ | ❌ | ❌ | ❌ |

---

### 5. `rol_contador` — Contador

| Tabla | SELECT | INSERT | UPDATE | DELETE |
|-------|:------:|:------:|:------:|:------:|
| `usuario` | ✅ | ❌ | ❌ | ❌ |
| `empresa` | ✅ | ❌ | ❌ | ❌ |
| `tipo_membresia` | ✅ | ❌ | ❌ | ❌ |
| `membresia` | ✅ | ❌ | ❌ | ❌ |
| `reserva` | ✅ | ❌ | ❌ | ❌ |
| `reserva_servicio` | ✅ | ❌ | ❌ | ❌ |
| `usuario_servicio` | ✅ | ❌ | ❌ | ❌ |
| `servicio_adicional` | ✅ | ❌ | ❌ | ❌ |
| `factura` | ✅ | ✅ | ✅ | ❌ |
| `detalle_factura` | ✅ | ✅ | ✅ | ❌ |
| `pago` | ✅ | ✅ | ✅ | ❌ |
| `reembolso_penalizacion` | ✅ | ✅ | ✅ | ❌ |

---

## Resumen comparativo

| Tabla | Admin | Recepcionista | Usuario | Gerente Corp. | Contador |
|-------|:-----:|:-------------:|:-------:|:-------------:|:--------:|
| `empresa` | CRUD | CRU | — | R | R |
| `usuario` | CRUD | CRU | — | CRU | R |
| `tipo_membresia` | CRUD | R | R | R | R |
| `membresia` | CRUD | CRU | R | CRU | R |
| `tipo_espacio` | CRUD | R | R | R | — |
| `espacio` | CRUD | CRU | R | R | — |
| `horario_espacio` | CRUD | CRU | R | — | — |
| `reserva` | CRUD | CRU | CRU | R | R |
| `reembolso_penalizacion` | CRUD | CR | R | R | CRU |
| `servicio_adicional` | CRUD | R | R | R | R |
| `reserva_servicio` | CRUD | CRU | CRU | R | R |
| `usuario_servicio` | CRUD | CRU | CR | R | R |
| `factura` | CRUD | R | R | R | CRU |
| `detalle_factura` | CRUD | R | R | R | CRU |
| `pago` | CRUD | R | R | R | CRU |
| `control_acceso` | CRUD | CRU | R | R | — |
| `log_auditoria` | CRUD | — | — | — | — |

**Leyenda:** C = CREATE (INSERT) · R = READ (SELECT) · U = UPDATE · D = DELETE · — = Sin acceso

---

## Asignación de roles a usuarios

| Usuario | Rol asignado |
|---------|--------------|
| `admin_coworking` | `rol_administrador` |
| `recepcionista` | `rol_recepcionista` |
| `usuario_app` | `rol_usuario` |
| `gerente_corporativo` | `rol_gerente_corporativo` |
| `contador` | `rol_contador` |