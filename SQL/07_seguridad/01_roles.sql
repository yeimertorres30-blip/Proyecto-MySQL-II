/*
PROYECTO: Gestión de Coworking y Oficinas Compartidas
GRUPO: 03 Exneider, Said, Alvaro, Hamilton, Yeimer
MÓDULO: Seguridad - Roles
ARCHIVO: 01_roles.sql
DESCRIPCIÓN: Creación de los 5 roles de base de datos exigidos en la sección 7
             del proyecto
             1. Administrador del Coworking 
             2. Recepcionista            
             3. Usuario                     
             4. Gerente Corporativo         
             5. Contador                    
REQUISITOS PREVIOS:
  - Ejecutar como usuario con privilegios de CREATE ROLE / GRANT.
  - MySQL 8.0+ (soporta roles nativos).
  - Base de datos coworking_db ya creada.
*/

USE coworking_db;

-- Limpieza de roles antiguos
DROP ROLE IF EXISTS 'rol_admin_coworking';
DROP ROLE IF EXISTS 'rol_recepcion';
DROP ROLE IF EXISTS 'rol_contabilidad';
DROP ROLE IF EXISTS 'rol_consulta';
DROP ROLE IF EXISTS 'rol_auditoria';
DROP ROLE IF EXISTS 'rol_administrador';
DROP ROLE IF EXISTS 'rol_recepcionista';
DROP ROLE IF EXISTS 'rol_usuario';
DROP ROLE IF EXISTS 'rol_gerente_corporativo';
DROP ROLE IF EXISTS 'rol_contador';

-- 1. ROL ADMINISTRADOR DEL COWORKING → Acceso total
CREATE ROLE IF NOT EXISTS 'rol_administrador';

-- 2. ROL RECEPCIONISTA → Registro de usuarios, asignación de membresías, gestión de reservas
CREATE ROLE IF NOT EXISTS 'rol_recepcionista';

-- 3. ROL USUARIO → Reservar espacios, consultar historial, descargar facturas
CREATE ROLE IF NOT EXISTS 'rol_usuario';

-- 4. ROL GERENTE CORPORATIVO → Administrar empleados de su empresa, ver facturación consolidada
CREATE ROLE IF NOT EXISTS 'rol_gerente_corporativo';

-- 5. ROL CONTADOR → Gestión de ingresos y reportes financieros
CREATE ROLE IF NOT EXISTS 'rol_contador';

-- VERIFICACIÓN
SELECT 
    User AS 'Rol creado',
    Host
FROM mysql.user
WHERE User LIKE 'rol_%'
ORDER BY User;