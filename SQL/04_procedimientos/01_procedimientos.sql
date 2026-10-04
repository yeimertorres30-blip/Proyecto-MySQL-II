/*
PROYECTO: Gestión de Coworking y Oficinas Compartidas
MÓDULO: Stored Procedures - Procedimientos Almacenados
ARCHIVO: 01_procedimientos.sql
DESCRIPCIÓN: Implementación de 20 procedimientos almacenados (`sp_`) para la
             gestión transaccional, lógica de negocio y automatización de procesos
             en la base de datos `coworking_db`.
*/

USE coworking_db;

DELIMITER $$

-- 1. sp_registrar_usuario
DROP PROCEDURE IF EXISTS sp_registrar_usuario$$
CREATE PROCEDURE sp_registrar_usuario(
    IN p_tipo_documento ENUM('CC', 'CE', 'PPT', 'TI'),
    IN p_tipo_usuario ENUM('empleado', 'comun'),
    IN p_numero_documento VARCHAR(20),
    IN p_primer_nombre VARCHAR(50),
    IN p_segundo_nombre VARCHAR(50),
    IN p_primer_apellido VARCHAR(50),
    IN p_segundo_apellido VARCHAR(50),
    IN p_fecha_nacimiento DATE,
    IN p_email VARCHAR(100),
    IN p_telefono VARCHAR(20),
    IN p_id_empresa INT,
    OUT p_id_usuario INT
)
BEGIN
    DECLARE v_existe INT;
    
    -- Validar duplicidad de documento o email
    SELECT COUNT(*) INTO v_existe FROM usuario WHERE numero_documento = p_numero_documento OR email = p_email;
    IF v_existe > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: El número de documento o correo electrónico ya se encuentra registrado.';
    END IF;

    INSERT INTO usuario (
        tipo_documento, tipo_usuario, numero_documento, primer_nombre, segundo_nombre,
        primer_apellido, segundo_apellido, fecha_nacimiento, email, telefono, id_empresa,
        codigo_qr, uid_rfid
    ) VALUES (
        p_tipo_documento, p_tipo_usuario, p_numero_documento, p_primer_nombre, p_segundo_nombre,
        p_primer_apellido, p_segundo_apellido, p_fecha_nacimiento, p_email, p_telefono, p_id_empresa,
        CONCAT('QR-', p_numero_documento), CONCAT('RFID-', UPPER(MD5(p_numero_documento)))
    );

    SET p_id_usuario = LAST_INSERT_ID();
    
    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    VALUES ('usuario', 'INSERT', CONCAT('Usuario registrado exitosamente con ID: ', p_id_usuario));
END$$


-- 2. sp_asignar_membresia
DROP PROCEDURE IF EXISTS sp_asignar_membresia$$
CREATE PROCEDURE sp_asignar_membresia(
    IN p_id_usuario INT,
    IN p_id_tipo_membresia INT,
    IN p_fecha_inicio DATE,
    OUT p_id_membresia INT
)
BEGIN
    DECLARE v_duracion INT;
    DECLARE v_precio DECIMAL(10,2);
    DECLARE v_fecha_vencimiento DATE;

    -- Obtener datos del tipo de membresía
    SELECT duracion_dias, precio_base INTO v_duracion, v_precio
    FROM tipo_membresia WHERE id_tipo_membresia = p_id_tipo_membresia;

    IF v_duracion IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Tipo de membresía no válido.';
    END IF;

    IF p_fecha_inicio IS NULL THEN
        SET p_fecha_inicio = CURRENT_DATE();
    END IF;

    SET v_fecha_vencimiento = DATE_ADD(p_fecha_inicio, INTERVAL v_duracion DAY);

    INSERT INTO membresia (id_usuario, id_tipo_membresia, fecha_inicio, fecha_vencimiento, estado, precio_cobrado)
    VALUES (p_id_usuario, p_id_tipo_membresia, p_fecha_inicio, v_fecha_vencimiento, 'activa', v_precio);

    SET p_id_membresia = LAST_INSERT_ID();

    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    VALUES ('membresia', 'INSERT', CONCAT('Membresía ID ', p_id_membresia, ' asignada al usuario ', p_id_usuario));
END$$


-- 3. sp_suspender_usuario
DROP PROCEDURE IF EXISTS sp_suspender_usuario$$
CREATE PROCEDURE sp_suspender_usuario(
    IN p_id_usuario INT,
    IN p_motivo VARCHAR(255)
)
BEGIN
    DECLARE v_filas INT;

    UPDATE membresia 
    SET estado = 'suspendida' 
    WHERE id_usuario = p_id_usuario AND estado = 'activa';

    SET v_filas = ROW_COUNT();

    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    VALUES ('membresia', 'UPDATE', CONCAT('Se suspendieron ', v_filas, ' membresías activas del usuario ', p_id_usuario, '. Motivo: ', p_motivo));
END$$


-- 4. sp_asociar_usuario_empresa
DROP PROCEDURE IF EXISTS sp_asociar_usuario_empresa$$
CREATE PROCEDURE sp_asociar_usuario_empresa(
    IN p_id_usuario INT,
    IN p_id_empresa INT
)
BEGIN
    DECLARE v_existe_empresa INT;

    IF p_id_empresa IS NOT NULL THEN
        SELECT COUNT(*) INTO v_existe_empresa FROM empresa WHERE id_empresa = p_id_empresa;
        IF v_existe_empresa = 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: La empresa especificada no existe.';
        END IF;
    END IF;

    UPDATE usuario 
    SET id_empresa = p_id_empresa, tipo_usuario = IF(p_id_empresa IS NOT NULL, 'empleado', 'comun')
    WHERE id_usuario = p_id_usuario;

    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    VALUES ('usuario', 'UPDATE', CONCAT('Usuario ', p_id_usuario, ' asociado a empresa ID: ', IFNULL(p_id_empresa, 'Ninguna')));
END$$

-- 5. sp_crear_reserva
DROP PROCEDURE IF EXISTS sp_crear_reserva$$
CREATE PROCEDURE sp_crear_reserva(
    IN p_id_usuario INT,
    IN p_id_espacio INT,
    IN p_fecha_reserva DATE,
    IN p_hora_inicio TIME,
    IN p_hora_fin TIME,
    IN p_numero_asistentes INT,
    OUT p_id_reserva INT
)
BEGIN
    DECLARE v_solapado INT;
    DECLARE v_capacidad INT;
    DECLARE v_estado_espacio VARCHAR(20);

    -- Verificar estado del espacio
    SELECT estado_disponibilidad, capacidad_maxima INTO v_estado_espacio, v_capacidad
    FROM espacio WHERE id_espacio = p_id_espacio;

    IF v_estado_espacio = 'mantenimiento' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: El espacio seleccionado se encuentra en mantenimiento.';
    END IF;

    IF p_numero_asistentes > v_capacidad THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: El número de asistentes excede la capacidad máxima del espacio.';
    END IF;

    -- Verificar solapamiento
    SELECT COUNT(*) INTO v_solapado
    FROM reserva
    WHERE id_espacio = p_id_espacio
      AND fecha_reserva = p_fecha_reserva
      AND estado_reserva IN ('pendiente', 'confirmada')
      AND (p_hora_inicio < hora_fin AND p_hora_fin > hora_inicio);

    IF v_solapado > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: El espacio ya se encuentra reservado en el rango horario solicitado.';
    END IF;

    INSERT INTO reserva (id_usuario, id_espacio, fecha_reserva, hora_inicio, hora_fin, numero_asistentes, estado_reserva)
    VALUES (p_id_usuario, p_id_espacio, p_fecha_reserva, p_hora_inicio, p_hora_fin, p_numero_asistentes, 'pendiente');

    SET p_id_reserva = LAST_INSERT_ID();

    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    VALUES ('reserva', 'INSERT', CONCAT('Reserva ID ', p_id_reserva, ' creada para usuario ', p_id_usuario, ' en espacio ', p_id_espacio));
END$$


-- 6. sp_cancelar_reserva
DROP PROCEDURE IF EXISTS sp_cancelar_reserva$$
CREATE PROCEDURE sp_cancelar_reserva(
    IN p_id_reserva INT,
    IN p_motivo VARCHAR(255)
)
BEGIN
    DECLARE v_estado VARCHAR(20);

    SELECT estado_reserva INTO v_estado FROM reserva WHERE id_reserva = p_id_reserva;

    IF v_estado IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: La reserva no existe.';
    END IF;

    IF v_estado = 'cancelada' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: La reserva ya se encuentra cancelada.';
    END IF;

    UPDATE reserva SET estado_reserva = 'cancelada' WHERE id_reserva = p_id_reserva;

    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    VALUES ('reserva', 'UPDATE', CONCAT('Reserva ID ', p_id_reserva, ' cancelada. Motivo: ', p_motivo));
END$$


-- 7. sp_confirmar_reserva
DROP PROCEDURE IF EXISTS sp_confirmar_reserva$$
CREATE PROCEDURE sp_confirmar_reserva(
    IN p_id_reserva INT
)
BEGIN
    DECLARE v_estado VARCHAR(20);

    SELECT estado_reserva INTO v_estado FROM reserva WHERE id_reserva = p_id_reserva;

    IF v_estado != 'pendiente' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Solo se pueden confirmar reservas en estado pendiente.';
    END IF;

    UPDATE reserva SET estado_reserva = 'confirmada' WHERE id_reserva = p_id_reserva;

    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    VALUES ('reserva', 'UPDATE', CONCAT('Reserva ID ', p_id_reserva, ' confirmada.'));
END$$


-- 8. sp_mantenimiento_espacio
DROP PROCEDURE IF EXISTS sp_mantenimiento_espacio$$
CREATE PROCEDURE sp_mantenimiento_espacio(
    IN p_id_espacio INT,
    IN p_motivo VARCHAR(255)
)
BEGIN
    -- Marcar espacio en mantenimiento
    UPDATE espacio SET estado_disponibilidad = 'mantenimiento' WHERE id_espacio = p_id_espacio;

    -- Cancelar reservas futuras pendientes o confirmadas
    UPDATE reserva 
    SET estado_reserva = 'cancelada' 
    WHERE id_espacio = p_id_espacio 
      AND fecha_reserva >= CURRENT_DATE() 
      AND estado_reserva IN ('pendiente', 'confirmada');

    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    VALUES ('espacio', 'UPDATE', CONCAT('Espacio ID ', p_id_espacio, ' puesto en mantenimiento. Motivo: ', p_motivo));
END$$

-- 9. sp_agregar_servicio_reserva
DROP PROCEDURE IF EXISTS sp_agregar_servicio_reserva$$
CREATE PROCEDURE sp_agregar_servicio_reserva(
    IN p_id_reserva INT,
    IN p_id_servicio INT,
    IN p_cantidad INT,
    OUT p_id_reserva_servicio INT
)
BEGIN
    DECLARE v_precio DECIMAL(10,2);

    SELECT precio_unitario INTO v_precio FROM servicio_adicional WHERE id_servicio = p_id_servicio;

    IF v_precio IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: El servicio adicional especificado no existe.';
    END IF;

    INSERT INTO reserva_servicio (id_reserva, id_servicio, cantidad, precio_aplicado)
    VALUES (p_id_reserva, p_id_servicio, p_cantidad, v_precio);

    SET p_id_reserva_servicio = LAST_INSERT_ID();

    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    VALUES ('reserva_servicio', 'INSERT', CONCAT('Servicio ID ', p_id_servicio, ' (cant: ', p_cantidad, ') agregado a reserva ID ', p_id_reserva));
END$$


-- 10. sp_contratar_servicio_usuario
DROP PROCEDURE IF EXISTS sp_contratar_servicio_usuario$$
CREATE PROCEDURE sp_contratar_servicio_usuario(
    IN p_id_usuario INT,
    IN p_id_servicio INT,
    IN p_cantidad INT,
    OUT p_id_usuario_servicio INT
)
BEGIN
    DECLARE v_precio DECIMAL(10,2);

    SELECT precio_unitario INTO v_precio FROM servicio_adicional WHERE id_servicio = p_id_servicio;

    IF v_precio IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: El servicio adicional especificado no existe.';
    END IF;

    INSERT INTO usuario_servicio (id_usuario, id_servicio, cantidad, precio_aplicado, fecha_contratacion)
    VALUES (p_id_usuario, p_id_servicio, p_cantidad, v_precio, CURRENT_DATE());

    SET p_id_usuario_servicio = LAST_INSERT_ID();

    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    VALUES ('usuario_servicio', 'INSERT', CONCAT('Servicio ID ', p_id_servicio, ' contratado directamente por usuario ID ', p_id_usuario));
END$$


-- 11. sp_actualizar_precio_servicio
DROP PROCEDURE IF EXISTS sp_actualizar_precio_servicio$$
CREATE PROCEDURE sp_actualizar_precio_servicio(
    IN p_id_servicio INT,
    IN p_nuevo_precio DECIMAL(10,2)
)
BEGIN
    DECLARE v_precio_anterior DECIMAL(10,2);

    SELECT precio_unitario INTO v_precio_anterior FROM servicio_adicional WHERE id_servicio = p_id_servicio;

    IF v_precio_anterior IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: El servicio no existe.';
    END IF;

    UPDATE servicio_adicional SET precio_unitario = p_nuevo_precio WHERE id_servicio = p_id_servicio;

    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    VALUES ('servicio_adicional', 'UPDATE', CONCAT('Precio del servicio ID ', p_id_servicio, ' actualizado de ', v_precio_anterior, ' a ', p_nuevo_precio));
END$$

-- 12. sp_generar_factura
DROP PROCEDURE IF EXISTS sp_generar_factura$$
CREATE PROCEDURE sp_generar_factura(
    IN p_id_usuario INT,
    IN p_monto_total DECIMAL(10,2),
    IN p_tipo_concepto VARCHAR(50),
    IN p_dias_vencimiento INT,
    OUT p_id_factura INT
)
BEGIN
    DECLARE v_id_empresa INT;
    DECLARE v_fecha_vencimiento DATE;

    SELECT id_empresa INTO v_id_empresa FROM usuario WHERE id_usuario = p_id_usuario;

    IF p_dias_vencimiento IS NULL OR p_dias_vencimiento <= 0 THEN
        SET p_dias_vencimiento = 15;
    END IF;

    SET v_fecha_vencimiento = DATE_ADD(CURRENT_DATE(), INTERVAL p_dias_vencimiento DAY);

    INSERT INTO factura (
        id_usuario, id_empresa, fecha_emision, fecha_vencimiento, monto_total, recargo, saldo_pendiente, tipo_concepto, estado_factura
    ) VALUES (
        p_id_usuario, v_id_empresa, CURRENT_DATE(), v_fecha_vencimiento, p_monto_total, 0.00, p_monto_total, p_tipo_concepto, 'pendiente'
    );

    SET p_id_factura = LAST_INSERT_ID();

    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    VALUES ('factura', 'INSERT', CONCAT('Factura ID ', p_id_factura, ' generada por monto de $', p_monto_total, ' para usuario ID ', p_id_usuario));
END$$


-- 13. sp_registrar_pago
DROP PROCEDURE IF EXISTS sp_registrar_pago$$
CREATE PROCEDURE sp_registrar_pago(
    IN p_id_factura INT,
    IN p_monto DECIMAL(10,2),
    IN p_metodo_pago ENUM('efectivo', 'tarjeta', 'transferencia', 'paypal'),
    OUT p_id_pago INT
)
BEGIN
    DECLARE v_id_usuario INT;
    DECLARE v_saldo DECIMAL(10,2);
    DECLARE v_estado VARCHAR(20);

    SELECT id_usuario, saldo_pendiente, estado_factura 
    INTO v_id_usuario, v_saldo, v_estado 
    FROM factura WHERE id_factura = p_id_factura;

    IF v_estado = 'anulada' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: No se pueden registrar pagos en facturas anuladas.';
    END IF;

    IF p_monto > v_saldo THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: El monto ingresado supera el saldo pendiente de la factura.';
    END IF;

    -- Iniciar transacción implícita de registro de pago
    INSERT INTO pago (id_factura, id_usuario, fecha_pago, monto, metodo_pago, estado_pago)
    VALUES (p_id_factura, v_id_usuario, NOW(), p_monto, p_metodo_pago, 'pagado');

    SET p_id_pago = LAST_INSERT_ID();

    -- El trigger trg_pago_after_insert_actualizar_factura se encargará de actualizar el saldo_pendiente y estado_factura.

    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    VALUES ('pago', 'INSERT', CONCAT('Pago ID ', p_id_pago, ' de $', p_monto, ' registrado para la factura ID ', p_id_factura));
END$$


-- 14. sp_anular_factura
DROP PROCEDURE IF EXISTS sp_anular_factura$$
CREATE PROCEDURE sp_anular_factura(
    IN p_id_factura INT,
    IN p_motivo VARCHAR(255)
)
BEGIN
    DECLARE v_estado VARCHAR(20);

    SELECT estado_factura INTO v_estado FROM factura WHERE id_factura = p_id_factura;

    IF v_estado IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: La factura no existe.';
    END IF;

    IF v_estado = 'anulada' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: La factura ya se encuentra anulada.';
    END IF;

    UPDATE factura 
    SET estado_factura = 'anulada', motivo_anulacion = p_motivo, saldo_pendiente = 0.00 
    WHERE id_factura = p_id_factura;

    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    VALUES ('factura', 'UPDATE', CONCAT('Factura ID ', p_id_factura, ' anulada. Motivo: ', p_motivo));
END$$


-- 15. sp_aplicar_descuento_factura
DROP PROCEDURE IF EXISTS sp_aplicar_descuento_factura$$
CREATE PROCEDURE sp_aplicar_descuento_factura(
    IN p_id_factura INT,
    IN p_monto_descuento DECIMAL(10,2)
)
BEGIN
    DECLARE v_monto_total DECIMAL(10,2);
    DECLARE v_saldo DECIMAL(10,2);

    SELECT monto_total, saldo_pendiente INTO v_monto_total, v_saldo 
    FROM factura WHERE id_factura = p_id_factura AND estado_factura = 'pendiente';

    IF v_monto_total IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: La factura no existe o no se encuentra pendiente.';
    END IF;

    IF p_monto_descuento >= v_monto_total THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: El descuento no puede ser mayor o igual al monto total de la factura.';
    END IF;

    UPDATE factura 
    SET monto_total = monto_total - p_monto_descuento,
        saldo_pendiente = LEAST(saldo_pendiente, monto_total - p_monto_descuento)
    WHERE id_factura = p_id_factura;

    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    VALUES ('factura', 'UPDATE', CONCAT('Descuento de $', p_monto_descuento, ' aplicado a la factura ID ', p_id_factura));
END$$

-- 16. sp_registrar_ingreso
DROP PROCEDURE IF EXISTS sp_registrar_ingreso$$
CREATE PROCEDURE sp_registrar_ingreso(
    IN p_codigo_leido VARCHAR(255),
    IN p_metodo ENUM('QR', 'RFID'),
    OUT p_id_acceso INT,
    OUT p_permitido BOOLEAN
)
BEGIN
    DECLARE v_id_usuario INT;
    DECLARE v_id_reserva INT;
    DECLARE v_membresia_activa INT;
    DECLARE v_reserva_activa INT;

    -- Buscar usuario por QR o RFID
    SELECT id_usuario INTO v_id_usuario 
    FROM usuario 
    WHERE codigo_qr = p_codigo_leido OR uid_rfid = p_codigo_leido;

    IF v_id_usuario IS NOT NULL THEN
        -- Verificar si tiene membresía activa
        SELECT COUNT(*) INTO v_membresia_activa 
        FROM membresia 
        WHERE id_usuario = v_id_usuario AND estado = 'activa' AND fecha_vencimiento >= CURRENT_DATE();

        -- Verificar si tiene reserva activa para hoy
        SELECT id_reserva INTO v_id_reserva 
        FROM reserva 
        WHERE id_usuario = v_id_usuario 
          AND fecha_reserva = CURRENT_DATE() 
          AND estado_reserva IN ('confirmada', 'pendiente')
        LIMIT 1;

        IF v_membresia_activa > 0 OR v_id_reserva IS NOT NULL THEN
            INSERT INTO control_acceso (id_usuario, id_reserva, fecha_hora_entrada, metodo_acceso, codigo_leido, estado_acceso)
            VALUES (v_id_usuario, v_id_reserva, NOW(), p_metodo, p_codigo_leido, 'permitido');
            
            SET p_id_acceso = LAST_INSERT_ID();
            SET p_permitido = TRUE;
        ELSE
            INSERT INTO control_acceso (id_usuario, id_reserva, fecha_hora_entrada, metodo_acceso, codigo_leido, estado_acceso, motivo_rechazo)
            VALUES (v_id_usuario, NULL, NOW(), p_metodo, p_codigo_leido, 'rechazado', 'Sin membresía activa ni reserva para la fecha');
            
            SET p_id_acceso = LAST_INSERT_ID();
            SET p_permitido = FALSE;
        END IF;
    ELSE
        INSERT INTO control_acceso (id_usuario, id_reserva, fecha_hora_entrada, metodo_acceso, codigo_leido, estado_acceso, motivo_rechazo)
        VALUES (NULL, NULL, NOW(), p_metodo, p_codigo_leido, 'rechazado', 'Código QR/RFID no reconocido');
        
        SET p_id_acceso = LAST_INSERT_ID();
        SET p_permitido = FALSE;
    END IF;
END$$


-- 17. sp_registrar_salida
DROP PROCEDURE IF EXISTS sp_registrar_salida$$
CREATE PROCEDURE sp_registrar_salida(
    IN p_id_acceso INT
)
BEGIN
    DECLARE v_salida DATETIME;

    SELECT fecha_hora_salida INTO v_salida FROM control_acceso WHERE id_acceso = p_id_acceso;

    IF v_salida IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Ya se encuentra registrada la hora de salida para este acceso.';
    END IF;

    UPDATE control_acceso SET fecha_hora_salida = NOW() WHERE id_acceso = p_id_acceso;

    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    VALUES ('control_acceso', 'UPDATE', CONCAT('Marcación de salida registrada para el acceso ID ', p_id_acceso));
END$$


-- 18. sp_reporte_consolidado_usuario
DROP PROCEDURE IF EXISTS sp_reporte_consolidado_usuario$$
CREATE PROCEDURE sp_reporte_consolidado_usuario(
    IN p_id_usuario INT
)
BEGIN
    SELECT 
        u.id_usuario,
        CONCAT(u.primer_nombre, ' ', u.primer_apellido) AS nombre_completo,
        u.email,
        u.telefono,
        e.razon_social AS empresa,
        fn_tipo_membresia_usuario(u.id_usuario) AS membresia_actual,
        fn_dias_restantes_membresia(u.id_usuario) AS dias_membresia_restantes,
        fn_total_reservas_usuario(u.id_usuario) AS total_reservas,
        fn_total_pagado_usuario(u.id_usuario) AS total_pagado,
        fn_saldo_pendiente_usuario(u.id_usuario) AS saldo_pendiente,
        fn_total_asistencias_usuario(u.id_usuario) AS total_asistencias,
        fn_ultima_fecha_ingreso(u.id_usuario) AS ultimo_ingreso
    FROM usuario u
    LEFT JOIN empresa e ON u.id_empresa = e.id_empresa
    WHERE u.id_usuario = p_id_usuario;
END$$


-- 19. sp_depurar_auditoria
DROP PROCEDURE IF EXISTS sp_depurar_auditoria$$
CREATE PROCEDURE sp_depurar_auditoria(
    IN p_fecha_corte DATETIME,
    OUT p_registros_eliminados INT
)
BEGIN
    DELETE FROM log_auditoria WHERE fecha_hora < p_fecha_corte;
    SET p_registros_eliminados = ROW_COUNT();

    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    VALUES ('log_auditoria', 'DELETE', CONCAT('Se depuraron ', p_registros_eliminados, ' registros de auditoría anteriores a ', p_fecha_corte));
END$$


-- 20. sp_recalculo_saldos_morosos
DROP PROCEDURE IF EXISTS sp_recalculo_saldos_morosos$$
CREATE PROCEDURE sp_recalculo_saldos_morosos(
    OUT p_facturas_afectadas INT
)
BEGIN
    -- Aplicar recargo del 5% a facturas vencidas sin recargo previo
    UPDATE factura 
    SET recargo = monto_total * 0.05,
        saldo_pendiente = saldo_pendiente + (monto_total * 0.05)
    WHERE estado_factura = 'pendiente' 
      AND fecha_vencimiento < CURRENT_DATE() 
      AND recargo = 0.00;

    SET p_facturas_afectadas = ROW_COUNT();

    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    VALUES ('factura', 'UPDATE', CONCAT('Recálculo de morosidad ejecutado. Facturas con recargo aplicado: ', p_facturas_afectadas));
END$$

DELIMITER ;
