/*
PROYECTO: Gestión de Coworking y Oficinas Compartidas
GRUPO: 03 Exneider, Said, Alvaro, Hamilton, Yeimer
MÓDULO: Seguridad - Usuarios de Base de Datos
ARCHIVO: 03_usuarios.sql
DESCRIPCIÓN: Creación de usuarios de aplicación MySQL y asignación de los 5 roles
             definidos en la sección 7 del proyecto:
               1. admin_coworking    
               2. recepcionista       
               3. usuario_app         
               4. gerente_corporativo
               5. contador            
REQUISITOS PREVIOS:
  - Ejecutar 01_roles.sql y 02_permisos.sql
  - Ejecutar como root o usuario con privilegios CREATE USER y GRANT
  - Cambiar las contraseñas por defecto en producción
NOTA SOBRE LAS CONEXIONES EN WORKBENCH:
  - "Yeimer" / admin_coworking 
  - recepcionista@localhost    
  - usuario_app@localhost      
  - gerente_corporativo@localhost 
  - contador@localhost         
*/

-- LIMPIEZA DE USUARIOS PREVIOS (idempotente)
DROP USER IF EXISTS 'admin_coworking'@'localhost';
DROP USER IF EXISTS 'admin_coworking'@'%';
DROP USER IF EXISTS 'recepcion'@'localhost';
DROP USER IF EXISTS 'recepcion'@'%';
DROP USER IF EXISTS 'recepcionista'@'localhost';
DROP USER IF EXISTS 'usuario_app'@'localhost';
DROP USER IF EXISTS 'gerente_corporativo'@'localhost';
DROP USER IF EXISTS 'contador'@'localhost';
DROP USER IF EXISTS 'contabilidad'@'localhost';
DROP USER IF EXISTS 'consulta'@'localhost';
DROP USER IF EXISTS 'auditor'@'localhost';

-- 1. USUARIO ADMINISTRADOR DEL COWORKING

CREATE USER IF NOT EXISTS 'admin_coworking'@'localhost'
    IDENTIFIED BY 'AdminCoworking2025!';

CREATE USER IF NOT EXISTS 'admin_coworking'@'%'
    IDENTIFIED BY 'AdminCoworking2025!';

GRANT 'rol_administrador' TO 'admin_coworking'@'localhost';
GRANT 'rol_administrador' TO 'admin_coworking'@'%';

SET DEFAULT ROLE 'rol_administrador' TO 'admin_coworking'@'localhost';
SET DEFAULT ROLE 'rol_administrador' TO 'admin_coworking'@'%';

-- 2. USUARIO RECEPCIONISTA

CREATE USER IF NOT EXISTS 'recepcionista'@'localhost'
    IDENTIFIED BY 'Recepcionista2025!';

GRANT 'rol_recepcionista' TO 'recepcionista'@'localhost';
SET DEFAULT ROLE 'rol_recepcionista' TO 'recepcionista'@'localhost';

-- 3. USUARIO (aplicación del usuario final)

CREATE USER IF NOT EXISTS 'usuario_app'@'localhost'
    IDENTIFIED BY 'UsuarioApp2025!';

GRANT 'rol_usuario' TO 'usuario_app'@'localhost';
SET DEFAULT ROLE 'rol_usuario' TO 'usuario_app'@'localhost';

-- 4. USUARIO GERENTE CORPORATIVO

CREATE USER IF NOT EXISTS 'gerente_corporativo'@'localhost'
    IDENTIFIED BY 'GerenteCorp2025!';

GRANT 'rol_gerente_corporativo' TO 'gerente_corporativo'@'localhost';
SET DEFAULT ROLE 'rol_gerente_corporativo' TO 'gerente_corporativo'@'localhost';

-- 5. USUARIO CONTADOR

CREATE USER IF NOT EXISTS 'contador'@'localhost'
    IDENTIFIED BY 'Contador2025!';

GRANT 'rol_contador' TO 'contador'@'localhost';
SET DEFAULT ROLE 'rol_contador' TO 'contador'@'localhost';

FLUSH PRIVILEGES;

-- Verificación de usuarios creados
SELECT 
    User AS 'Usuario',
    Host AS 'Host',
    account_locked AS 'Bloqueado',
    password_expired AS 'Pwd expirada'
FROM mysql.user
WHERE User IN (
    'admin_coworking',
    'recepcionista',
    'usuario_app',
    'gerente_corporativo',
    'contador'
)
ORDER BY User, Host;

-- Verificación de asignación de roles
SELECT 
    FROM_USER AS 'Usuario',
    TO_USER   AS 'Rol asignado',
    TO_HOST   AS 'Host del rol'
FROM mysql.role_edges
WHERE FROM_USER IN (
    'admin_coworking',
    'recepcionista',
    'usuario_app',
    'gerente_corporativo',
    'contador'
)
ORDER BY FROM_USER;

-- Muestra de grants de ejemplo
SHOW GRANTS FOR 'recepcionista'@'localhost';
SHOW GRANTS FOR 'admin_coworking'@'localhost';
SHOW GRANTS FOR 'usuario_app'@'localhost';
SHOW GRANTS FOR 'gerente_corporativo'@'localhost';
SHOW GRANTS FOR 'contador'@'localhost';