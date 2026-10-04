/*
PROYECTO: Gestión de Coworking y Oficinas Compartidas
GRUPO: 03 Exneider, Said, Alvaro, Hamilton, Yeimer
MÓDULO: Seguridad
ARCHIVO: 02_permisos.sql
DESCRIPCIÓN: Asignación de privilegios a los 5 roles definidos en 01_roles.sql
             según el principio de mínimo privilegio y la sección 7 del proyecto.
REQUISITOS PREVIOS:
  - Ejecutar primero 01_roles.sql
  - Ejecutar como usuario con privilegios GRANT OPTION sobre coworking_db
  - Base de datos coworking_db y todas sus tablas creadas
*/

USE coworking_db;

/*
   1. ROL ADMINISTRADOR DEL COWORKING
      Acceso total a la base de datos y privilegios de administración básicos.
      */
GRANT ALL PRIVILEGES ON coworking_db.* TO 'rol_administrador';
GRANT CREATE USER, RELOAD, PROCESS ON *.* TO 'rol_administrador';

/*
   2. ROL RECEPCIONISTA
      Registro de usuarios, asignación de membresías y gestión de reservas.
      Puede consultar estado de facturación (solo lectura) para atender clientes.
      */
-- Entidades de usuarios y empresas
GRANT SELECT, INSERT, UPDATE ON coworking_db.empresa            TO 'rol_recepcionista';
GRANT SELECT, INSERT, UPDATE ON coworking_db.usuario            TO 'rol_recepcionista';

-- Membresías
GRANT SELECT, INSERT, UPDATE ON coworking_db.membresia          TO 'rol_recepcionista';
GRANT SELECT                 ON coworking_db.tipo_membresia     TO 'rol_recepcionista';

-- Espacios y horarios
GRANT SELECT, INSERT, UPDATE ON coworking_db.espacio            TO 'rol_recepcionista';
GRANT SELECT                 ON coworking_db.tipo_espacio       TO 'rol_recepcionista';
GRANT SELECT, INSERT, UPDATE ON coworking_db.horario_espacio    TO 'rol_recepcionista';

-- Reservas y servicios asociados
GRANT SELECT, INSERT, UPDATE ON coworking_db.reserva            TO 'rol_recepcionista';
GRANT SELECT, INSERT, UPDATE ON coworking_db.reserva_servicio   TO 'rol_recepcionista';
GRANT SELECT                 ON coworking_db.servicio_adicional TO 'rol_recepcionista';
GRANT SELECT, INSERT, UPDATE ON coworking_db.usuario_servicio   TO 'rol_recepcionista';

-- Control de acceso y penalizaciones
GRANT SELECT, INSERT, UPDATE ON coworking_db.control_acceso     TO 'rol_recepcionista';
GRANT SELECT, INSERT         ON coworking_db.reembolso_penalizacion TO 'rol_recepcionista';

-- Solo lectura de facturación (consulta de estado al cliente)
GRANT SELECT ON coworking_db.factura         TO 'rol_recepcionista';
GRANT SELECT ON coworking_db.detalle_factura TO 'rol_recepcionista';
GRANT SELECT ON coworking_db.pago            TO 'rol_recepcionista';

/*
   3. ROL USUARIO
      Reservar espacios, consultar su historial y descargar/ver facturas.
      Permisos orientados a operaciones del propio usuario (el filtrado por
      usuario_id se realiza a nivel de aplicación).
      */
-- Consulta de catálogos necesarios para reservar
GRANT SELECT ON coworking_db.tipo_espacio       TO 'rol_usuario';
GRANT SELECT ON coworking_db.espacio            TO 'rol_usuario';
GRANT SELECT ON coworking_db.horario_espacio    TO 'rol_usuario';
GRANT SELECT ON coworking_db.tipo_membresia     TO 'rol_usuario';
GRANT SELECT ON coworking_db.servicio_adicional TO 'rol_usuario';

-- Gestión de sus propias reservas
GRANT SELECT, INSERT, UPDATE ON coworking_db.reserva            TO 'rol_usuario';
GRANT SELECT, INSERT, UPDATE ON coworking_db.reserva_servicio   TO 'rol_usuario';
GRANT SELECT, INSERT         ON coworking_db.usuario_servicio   TO 'rol_usuario';

-- Consulta de su historial de membresía, accesos y facturación
GRANT SELECT ON coworking_db.membresia          TO 'rol_usuario';
GRANT SELECT ON coworking_db.control_acceso     TO 'rol_usuario';
GRANT SELECT ON coworking_db.factura            TO 'rol_usuario';
GRANT SELECT ON coworking_db.detalle_factura    TO 'rol_usuario';
GRANT SELECT ON coworking_db.pago               TO 'rol_usuario';
GRANT SELECT ON coworking_db.reembolso_penalizacion TO 'rol_usuario';

/*
   4. ROL GERENTE CORPORATIVO
      Administrar empleados de su empresa y ver facturación consolidada.
      (El filtrado por empresa se realiza a nivel de aplicación).
	*/
-- Administración de empleados de la empresa
GRANT SELECT, INSERT, UPDATE ON coworking_db.usuario            TO 'rol_gerente_corporativo';
GRANT SELECT                 ON coworking_db.empresa            TO 'rol_gerente_corporativo';

-- Membresías de la empresa / empleados
GRANT SELECT, INSERT, UPDATE ON coworking_db.membresia          TO 'rol_gerente_corporativo';
GRANT SELECT                 ON coworking_db.tipo_membresia     TO 'rol_gerente_corporativo';

-- Consulta de reservas y servicios de los empleados
GRANT SELECT ON coworking_db.reserva            TO 'rol_gerente_corporativo';
GRANT SELECT ON coworking_db.reserva_servicio   TO 'rol_gerente_corporativo';
GRANT SELECT ON coworking_db.usuario_servicio   TO 'rol_gerente_corporativo';
GRANT SELECT ON coworking_db.servicio_adicional TO 'rol_gerente_corporativo';
GRANT SELECT ON coworking_db.espacio            TO 'rol_gerente_corporativo';
GRANT SELECT ON coworking_db.tipo_espacio       TO 'rol_gerente_corporativo';

-- Facturación consolidada de la empresa
GRANT SELECT ON coworking_db.factura            TO 'rol_gerente_corporativo';
GRANT SELECT ON coworking_db.detalle_factura    TO 'rol_gerente_corporativo';
GRANT SELECT ON coworking_db.pago               TO 'rol_gerente_corporativo';
GRANT SELECT ON coworking_db.reembolso_penalizacion TO 'rol_gerente_corporativo';

-- Control de acceso de los empleados
GRANT SELECT ON coworking_db.control_acceso     TO 'rol_gerente_corporativo';

/* 
	5. ROL CONTADOR
      Gestión de ingresos y reportes financieros.
      */
-- Datos maestros necesarios para reportes
GRANT SELECT ON coworking_db.usuario            TO 'rol_contador';
GRANT SELECT ON coworking_db.empresa            TO 'rol_contador';
GRANT SELECT ON coworking_db.tipo_membresia     TO 'rol_contador';
GRANT SELECT ON coworking_db.membresia          TO 'rol_contador';
GRANT SELECT ON coworking_db.reserva            TO 'rol_contador';
GRANT SELECT ON coworking_db.reserva_servicio   TO 'rol_contador';
GRANT SELECT ON coworking_db.usuario_servicio   TO 'rol_contador';
GRANT SELECT ON coworking_db.servicio_adicional TO 'rol_contador';

-- Gestión completa de facturación e ingresos
GRANT SELECT, INSERT, UPDATE ON coworking_db.factura            TO 'rol_contador';
GRANT SELECT, INSERT, UPDATE ON coworking_db.detalle_factura    TO 'rol_contador';
GRANT SELECT, INSERT, UPDATE ON coworking_db.pago               TO 'rol_contador';
GRANT SELECT, INSERT, UPDATE ON coworking_db.reembolso_penalizacion TO 'rol_contador';

FLUSH PRIVILEGES;

-- Verificación de privilegios
SHOW GRANTS FOR 'rol_administrador';
SHOW GRANTS FOR 'rol_recepcionista';
SHOW GRANTS FOR 'rol_usuario';
SHOW GRANTS FOR 'rol_gerente_corporativo';
SHOW GRANTS FOR 'rol_contador';