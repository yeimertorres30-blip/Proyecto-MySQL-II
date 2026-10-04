/*
PROYECTO: Gestión de Coworking y Oficinas Compartidas
MÓDULO: Triggers SQL (Disparadores de Automatización y Validación)
ARCHIVO: 01_triggers.sql
DESCRIPCIÓN: Implementación de 20 triggers automatizados para validaciones de
             negocio, integridad referencial, mantenimiento de saldos y logs
             de auditoría, siguiendo las buenas prácticas y nomenclatura trg_.
*/

USE coworking_db;

DELIMITER $$

-- 1. Validar que el usuario sea mayor de edad (>= 18 años) antes de registrarlo
DROP TRIGGER IF EXISTS trg_usuario_before_insert_validar_edad$$
CREATE TRIGGER trg_usuario_before_insert_validar_edad
BEFORE INSERT ON usuario
FOR EACH ROW
BEGIN
    IF (DATEDIFF(CURRENT_DATE, NEW.fecha_nacimiento) / 365.25) < 18 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error de Negocio: El usuario debe ser mayor de 18 años.';
    END IF;
END$$

-- 2. Registrar en auditoría la creación de un nuevo usuario
DROP TRIGGER IF EXISTS trg_usuario_after_insert_audit$$
CREATE TRIGGER trg_usuario_after_insert_audit
AFTER INSERT ON usuario
FOR EACH ROW
BEGIN
    INSERT INTO log_auditoria (tabla_afectada, operacion, usuario_bd, descripcion)
    VALUES (
        'usuario', 
        'INSERT', 
        CURRENT_USER(), 
        CONCAT('Nuevo usuario creado: ID ', NEW.id_usuario, ' - ', NEW.primer_nombre, ' ', NEW.primer_apellido, ' (Doc: ', NEW.numero_documento, ')')
    );
END$$

-- 3. Registrar en auditoría cambios en datos sensibles del usuario
DROP TRIGGER IF EXISTS trg_usuario_after_update_audit$$
CREATE TRIGGER trg_usuario_after_update_audit
AFTER UPDATE ON usuario
FOR EACH ROW
BEGIN
    IF OLD.email <> NEW.email OR OLD.telefono <> NEW.telefono OR OLD.id_empresa <=> NEW.id_empresa THEN
        INSERT INTO log_auditoria (tabla_afectada, operacion, usuario_bd, descripcion)
        VALUES (
            'usuario', 
            'UPDATE', 
            CURRENT_USER(), 
            CONCAT('Actualización de usuario ID ', NEW.id_usuario, ': Email anterior (', OLD.email, ') -> Nuevo (', NEW.email, ')')
        );
    END IF;
END$$

-- 4. Validar fechas de membresía y autocompletar precio_cobrado si es cero
DROP TRIGGER IF EXISTS trg_membresia_before_insert_validar$$
CREATE TRIGGER trg_membresia_before_insert_validar
BEFORE INSERT ON membresia
FOR EACH ROW
BEGIN
    DECLARE v_precio DECIMAL(10,2);
    
    IF NEW.fecha_vencimiento < NEW.fecha_inicio THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error de Fechas: La fecha de vencimiento no puede ser anterior a la fecha de inicio.';
    END IF;

    IF NEW.precio_cobrado IS NULL OR NEW.precio_cobrado = 0 THEN
        SELECT precio_base INTO v_precio FROM tipo_membresia WHERE id_tipo_membresia = NEW.id_tipo_membresia;
        SET NEW.precio_cobrado = v_precio;
    END IF;
END$$

-- 5. Auditoría tras asignar una nueva membresía
DROP TRIGGER IF EXISTS trg_membresia_after_insert_audit$$
CREATE TRIGGER trg_membresia_after_insert_audit
AFTER INSERT ON membresia
FOR EACH ROW
BEGIN
    INSERT INTO log_auditoria (tabla_afectada, operacion, usuario_bd, descripcion)
    VALUES (
        'membresia', 
        'INSERT', 
        CURRENT_USER(), 
        CONCAT('Membresía ID ', NEW.id_membresia, ' asignada al Usuario ID ', NEW.id_usuario, ' (Tipo ID: ', NEW.id_tipo_membresia, ')')
    );
END$$

-- 6. Auditoría cuando el estado de una membresía cambia a suspendida o vencida
DROP TRIGGER IF EXISTS trg_membresia_after_update_estado$$
CREATE TRIGGER trg_membresia_after_update_estado
AFTER UPDATE ON membresia
FOR EACH ROW
BEGIN
    IF OLD.estado <> NEW.estado THEN
        INSERT INTO log_auditoria (tabla_afectada, operacion, usuario_bd, descripcion)
        VALUES (
            'membresia', 
            'UPDATE', 
            CURRENT_USER(), 
            CONCAT('Membresía ID ', NEW.id_membresia, ' cambió estado de ', OLD.estado, ' a ', NEW.estado)
        );
    END IF;
END$$

-- 7. Validar que la hora final de la reserva sea mayor a la inicial y espacio disponible
DROP TRIGGER IF EXISTS trg_reserva_before_insert_validar$$
CREATE TRIGGER trg_reserva_before_insert_validar
BEFORE INSERT ON reserva
FOR EACH ROW
BEGIN
    DECLARE v_estado VARCHAR(20);
    
    IF NEW.hora_fin <= NEW.hora_inicio THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error de Horario: La hora de fin debe ser posterior a la hora de inicio.';
    END IF;

    SELECT estado_disponibilidad INTO v_estado FROM espacio WHERE id_espacio = NEW.id_espacio;
    IF v_estado = 'mantenimiento' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Espacio no disponible: El espacio seleccionado se encuentra en mantenimiento.';
    END IF;
END$$

-- 8. Validar solapamiento de horarios en reservas para el mismo espacio
DROP TRIGGER IF EXISTS trg_reserva_before_insert_solapamiento$$
CREATE TRIGGER trg_reserva_before_insert_solapamiento
BEFORE INSERT ON reserva
FOR EACH ROW
BEGIN
    DECLARE v_conteo INT;
    
    SELECT COUNT(*) INTO v_conteo
    FROM reserva
    WHERE id_espacio = NEW.id_espacio
      AND fecha_reserva = NEW.fecha_reserva
      AND estado_reserva IN ('pendiente', 'confirmada')
      AND (
          (NEW.hora_inicio >= hora_inicio AND NEW.hora_inicio < hora_fin) OR
          (NEW.hora_fin > hora_inicio AND NEW.hora_fin <= hora_fin) OR
          (NEW.hora_inicio <= hora_inicio AND NEW.hora_fin >= hora_fin)
      );

    IF v_conteo > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Conflicto de Reserva: Ya existe una reserva activa para este espacio en el rango de horas solicitado.';
    END IF;
END$$

-- 9. Registrar auditoría tras la inserción de una reserva
DROP TRIGGER IF EXISTS trg_reserva_after_insert_audit$$
CREATE TRIGGER trg_reserva_after_insert_audit
AFTER INSERT ON reserva
FOR EACH ROW
BEGIN
    INSERT INTO log_auditoria (tabla_afectada, operacion, usuario_bd, descripcion)
    VALUES (
        'reserva', 
        'INSERT', 
        CURRENT_USER(), 
        CONCAT('Nueva reserva ID ', NEW.id_reserva, ' creada para Usuario ID ', NEW.id_usuario, ' en Espacio ID ', NEW.id_espacio)
    );
END$$

-- 10. Actualizar disponibilidad del espacio al confirmar o cancelar una reserva
DROP TRIGGER IF EXISTS trg_reserva_after_update_estado_espacio$$
CREATE TRIGGER trg_reserva_after_update_estado_espacio
AFTER UPDATE ON reserva
FOR EACH ROW
BEGIN
    IF NEW.estado_reserva = 'confirmada' AND OLD.estado_reserva <> 'confirmada' THEN
        UPDATE espacio SET estado_disponibilidad = 'ocupado' WHERE id_espacio = NEW.id_espacio;
    ELSEIF NEW.estado_reserva IN ('cancelada', 'completada', 'no_show') AND OLD.estado_reserva = 'confirmada' THEN
        UPDATE espacio SET estado_disponibilidad = 'disponible' WHERE id_espacio = NEW.id_espacio;
    END IF;
END$$

-- 11. Impedir la eliminación de reservas confirmadas
DROP TRIGGER IF EXISTS trg_reserva_before_delete_impedir$$
CREATE TRIGGER trg_reserva_before_delete_impedir
BEFORE DELETE ON reserva
FOR EACH ROW
BEGIN
    IF OLD.estado_reserva = 'confirmada' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Restricción de Borrado: No se pueden eliminar reservas en estado confirmada. Cancele la reserva primero.';
    END IF;
END$$

-- 12. Asignar precio unitario automáticamente en reserva_servicio
DROP TRIGGER IF EXISTS trg_reserva_servicio_before_insert_precio$$
CREATE TRIGGER trg_reserva_servicio_before_insert_precio
BEFORE INSERT ON reserva_servicio
FOR EACH ROW
BEGIN
    DECLARE v_precio DECIMAL(10,2);
    IF NEW.precio_aplicado IS NULL OR NEW.precio_aplicado = 0 THEN
        SELECT precio_unitario INTO v_precio FROM servicio_adicional WHERE id_servicio = NEW.id_servicio;
        SET NEW.precio_aplicado = v_precio;
    END IF;
END$$

-- 13. Asignar precio unitario automáticamente en usuario_servicio
DROP TRIGGER IF EXISTS trg_usuario_servicio_before_insert_precio$$
CREATE TRIGGER trg_usuario_servicio_before_insert_precio
BEFORE INSERT ON usuario_servicio
FOR EACH ROW
BEGIN
    DECLARE v_precio DECIMAL(10,2);
    IF NEW.precio_aplicado IS NULL OR NEW.precio_aplicado = 0 THEN
        SELECT precio_unitario INTO v_precio FROM servicio_adicional WHERE id_servicio = NEW.id_servicio;
        SET NEW.precio_aplicado = v_precio;
    END IF;
END$$

-- 14. Calcular el saldo pendiente al emitir una factura
DROP TRIGGER IF EXISTS trg_factura_before_insert_saldo$$
CREATE TRIGGER trg_factura_before_insert_saldo
BEFORE INSERT ON factura
FOR EACH ROW
BEGIN
    IF NEW.saldo_pendiente IS NULL OR NEW.saldo_pendiente = 0 THEN
        SET NEW.saldo_pendiente = NEW.monto_total + NEW.recargo;
    END IF;
END$$

-- 15. Exigir motivo de anulación si la factura cambia a estado anulada
DROP TRIGGER IF EXISTS trg_factura_before_update_anulacion$$
CREATE TRIGGER trg_factura_before_update_anulacion
BEFORE UPDATE ON factura
FOR EACH ROW
BEGIN
    IF NEW.estado_factura = 'anulada' AND (NEW.motivo_anulacion IS NULL OR TRIM(NEW.motivo_anulacion) = '') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error de Anulación: Debe proporcionar un motivo para anular la factura.';
    END IF;
END$$

-- 16. Validar que el pago no supere el saldo pendiente de la factura
DROP TRIGGER IF EXISTS trg_pago_before_insert_validar_monto$$
CREATE TRIGGER trg_pago_before_insert_validar_monto
BEFORE INSERT ON pago
FOR EACH ROW
BEGIN
    DECLARE v_saldo DECIMAL(10,2);
    SELECT saldo_pendiente INTO v_saldo FROM factura WHERE id_factura = NEW.id_factura;
    
    IF NEW.monto > v_saldo THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error de Pago: El monto ingresado supera el saldo pendiente de la factura.';
    END IF;
END$$

-- 17. Actualizar automáticamente el saldo pendiente y estado de la factura tras un pago
DROP TRIGGER IF EXISTS trg_pago_after_insert_actualizar_factura$$
CREATE TRIGGER trg_pago_after_insert_actualizar_factura
AFTER INSERT ON pago
FOR EACH ROW
BEGIN
    UPDATE factura 
    SET saldo_pendiente = saldo_pendiente - NEW.monto
    WHERE id_factura = NEW.id_factura;

    UPDATE factura
    SET estado_factura = 'pagada'
    WHERE id_factura = NEW.id_factura AND saldo_pendiente <= 0;
END$$

-- 18. Actualizar automáticamente la fecha del último acceso del usuario al ingresar
DROP TRIGGER IF EXISTS trg_control_acceso_after_insert_ultimo_acceso$$
CREATE TRIGGER trg_control_acceso_after_insert_ultimo_acceso
AFTER INSERT ON control_acceso
FOR EACH ROW
BEGIN
    IF NEW.estado_acceso = 'permitido' AND NEW.id_usuario IS NOT NULL THEN
        UPDATE usuario 
        SET ultima_fecha_acceso = NEW.fecha_hora_entrada 
        WHERE id_usuario = NEW.id_usuario;
    END IF;
END$$

-- 19. Auditoría de cambios en la disponibilidad de espacios
DROP TRIGGER IF EXISTS trg_espacio_after_update_audit$$
CREATE TRIGGER trg_espacio_after_update_audit
AFTER UPDATE ON espacio
FOR EACH ROW
BEGIN
    IF OLD.estado_disponibilidad <> NEW.estado_disponibilidad THEN
        INSERT INTO log_auditoria (tabla_afectada, operacion, usuario_bd, descripcion)
        VALUES (
            'espacio', 
            'UPDATE', 
            CURRENT_USER(), 
            CONCAT('Espacio ID ', NEW.id_espacio, ' (', NEW.codigo_espacio, ') cambió estado de ', OLD.estado_disponibilidad, ' a ', NEW.estado_disponibilidad)
        );
    END IF;
END$$

-- 20. Auditoría de eliminaciones en el catálogo de servicios adicionales
DROP TRIGGER IF EXISTS trg_servicio_adicional_after_delete_audit$$
CREATE TRIGGER trg_servicio_adicional_after_delete_audit
AFTER DELETE ON servicio_adicional
FOR EACH ROW
BEGIN
    INSERT INTO log_auditoria (tabla_afectada, operacion, usuario_bd, descripcion)
    VALUES (
        'servicio_adicional', 
        'DELETE', 
        CURRENT_USER(), 
        CONCAT('Servicio eliminado ID ', OLD.id_servicio, ': ', OLD.nombre, ' (Precio: $', OLD.precio_unitario, ')')
    );
END$$

DELIMITER ;
