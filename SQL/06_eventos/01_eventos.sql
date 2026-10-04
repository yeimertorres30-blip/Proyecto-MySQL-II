/*
PROYECTO: Gestión de Coworking y Oficinas Compartidas
MÓDULO: Eventos Programados (Event Scheduler)
ARCHIVO: 01_eventos.sql
DESCRIPCIÓN: Definición e implementación de 20 eventos automáticos por tiempo
             (evt_) para mantenimiento, facturación, sincronización y reportes.
*/

USE coworking_db;

-- Habilitar el programador de eventos de MySQL de manera global
SET GLOBAL event_scheduler = ON;

DELIMITER $$

-- 1. Actualizar estado de membresías vencidas diariamente
DROP EVENT IF EXISTS evt_actualizar_membresias_vencidas$$
CREATE EVENT evt_actualizar_membresias_vencidas
ON SCHEDULE EVERY 1 DAY
STARTS (CURRENT_DATE + INTERVAL 1 DAY + INTERVAL 1 MINUTE)
DO
BEGIN
    UPDATE membresia
    SET estado = 'vencida'
    WHERE fecha_vencimiento < CURRENT_DATE 
      AND estado = 'activa';
      
    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    VALUES ('membresia', 'UPDATE_EVENT', 'Evento evt_actualizar_membresias_vencidas ejecutado con éxito.');
END$$

-- 2. Suspender membresías con facturas vencidas por más de 15 días
DROP EVENT IF EXISTS evt_suspender_membresias_impagadas$$
CREATE EVENT evt_suspender_membresias_impagadas
ON SCHEDULE EVERY 1 DAY
STARTS (CURRENT_DATE + INTERVAL 1 DAY + INTERVAL 5 MINUTE)
DO
BEGIN
    UPDATE membresia m
    INNER JOIN factura f ON m.id_usuario = f.id_usuario
    SET m.estado = 'suspendida'
    WHERE f.estado_factura = 'pendiente'
      AND f.fecha_vencimiento < (CURRENT_DATE - INTERVAL 15 DAY)
      AND m.estado = 'activa';
      
    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    VALUES ('membresia', 'UPDATE_EVENT', 'Membresías suspendidas por mora mayor a 15 días.');
END$$

-- 3. Notificar/Registrar alerta para membresías próximas a vencer (3 días antes)
DROP EVENT IF EXISTS evt_notificar_vencimiento_proximo$$
CREATE EVENT evt_notificar_vencimiento_proximo
ON SCHEDULE EVERY 1 DAY
STARTS (CURRENT_DATE + INTERVAL 1 DAY + INTERVAL 10 MINUTE)
DO
BEGIN
    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    SELECT 
        'membresia', 
        'ALERT_EVENT', 
        CONCAT('ALERTA: La membresía ID ', m.id_membresia, ' del usuario ID ', m.id_usuario, ' vence en 3 días (', m.fecha_vencimiento, ').')
    FROM membresia m
    WHERE m.estado = 'activa' 
      AND m.fecha_vencimiento = (CURRENT_DATE + INTERVAL 3 DAY);
END$$

-- 4. Inactivar y limpiar códigos QR/RFID de usuarios sin membresía activa por más de 6 meses
DROP EVENT IF EXISTS evt_limpiar_codigos_inactivos$$
CREATE EVENT evt_limpiar_codigos_inactivos
ON SCHEDULE EVERY 1 MONTH
STARTS (CURRENT_DATE + INTERVAL 1 MONTH)
DO
BEGIN
    UPDATE usuario u
    LEFT JOIN membresia m ON u.id_usuario = m.id_usuario AND m.estado = 'activa'
    SET u.codigo_qr = NULL, u.uid_rfid = NULL
    WHERE m.id_membresia IS NULL
      AND (u.ultima_fecha_acceso < (CURRENT_DATE - INTERVAL 6 MONTH) OR u.ultima_fecha_acceso IS NULL);
      
    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    VALUES ('usuario', 'CLEANUP_EVENT', 'Limpieza mensual de QR/RFID de usuarios inactivos realizada.');
END$$

-- 5. Cancelar reservas pendientes cuya hora de inicio ya transcurrió sin confirmación
DROP EVENT IF EXISTS evt_cancelar_reservas_sin_confirmar$$
CREATE EVENT evt_cancelar_reservas_sin_confirmar
ON SCHEDULE EVERY 15 MINUTE
DO
BEGIN
    UPDATE reserva
    SET estado_reserva = 'cancelada'
    WHERE estado_reserva = 'pendiente'
      AND CONCAT(fecha_reserva, ' ', hora_inicio) <= NOW();
      
    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    VALUES ('reserva', 'UPDATE_EVENT', 'Depuración de reservas pendientes no confirmadas.');
END$$

-- 6. Marcar reservas confirmadas como completadas una vez finalizado el horario
DROP EVENT IF EXISTS evt_completar_reservas_pasadas$$
CREATE EVENT evt_completar_reservas_pasadas
ON SCHEDULE EVERY 1 HOUR
DO
BEGIN
    UPDATE reserva
    SET estado_reserva = 'completada'
    WHERE estado_reserva = 'confirmada'
      AND CONCAT(fecha_reserva, ' ', hora_fin) <= NOW();
      
    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    VALUES ('reserva', 'UPDATE_EVENT', 'Actualización automática de reservas a estado completada.');
END$$

-- 7. Restablecer espacios ocupados o en mantenimiento a estado disponible si no tienen reservas activas
DROP EVENT IF EXISTS evt_liberar_espacios_disponibles$$
CREATE EVENT evt_liberar_espacios_disponibles
ON SCHEDULE EVERY 30 MINUTE
DO
BEGIN
    UPDATE espacio e
    SET e.estado_disponibilidad = 'disponible'
    WHERE e.estado_disponibilidad = 'ocupado'
      AND NOT EXISTS (
          SELECT 1 FROM reserva r
          WHERE r.id_espacio = e.id_espacio
            AND r.estado_reserva = 'confirmada'
            AND r.fecha_reserva = CURRENT_DATE
            AND CURRENT_TIME BETWEEN r.hora_inicio AND r.hora_fin
      );
END$$

-- 8. Marcar como No Show las reservas confirmadas donde el usuario no ingresó durante la primera hora
DROP EVENT IF EXISTS evt_marcar_no_show_reservas$$
CREATE EVENT evt_marcar_no_show_reservas
ON SCHEDULE EVERY 1 HOUR
DO
BEGIN
    UPDATE reserva r
    LEFT JOIN control_acceso ca ON r.id_usuario = ca.id_usuario 
        AND ca.fecha_hora_entrada BETWEEN CONCAT(r.fecha_reserva, ' ', r.hora_inicio) AND CONCAT(r.fecha_reserva, ' ', r.hora_fin)
        AND ca.estado_acceso = 'permitido'
    SET r.estado_reserva = 'no_show'
    WHERE r.estado_reserva = 'confirmada'
      AND CONCAT(r.fecha_reserva, ' ', r.hora_inicio) < (NOW() - INTERVAL 1 HOUR)
      AND ca.id_acceso IS NULL;
END$$

-- 9. Resumen mensual de los servicios adicionales más demandados
DROP EVENT IF EXISTS evt_resumen_mensual_servicios_top$$
CREATE EVENT evt_resumen_mensual_servicios_top
ON SCHEDULE EVERY 1 MONTH
STARTS (CURRENT_DATE + INTERVAL 1 MONTH)
DO
BEGIN
    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    SELECT 
        'servicio_adicional',
        'SUMMARY_EVENT',
        CONCAT('REPORTE MES: Servicio Top "', sa.nombre, '" con ', SUM(rs.cantidad), ' unidades consumidas.')
    FROM reserva_servicio rs
    JOIN servicio_adicional sa ON rs.id_servicio = sa.id_servicio
    JOIN reserva r ON rs.id_reserva = r.id_reserva
    WHERE r.fecha_reserva >= (CURRENT_DATE - INTERVAL 1 MONTH)
    GROUP BY sa.id_servicio, sa.nombre
    ORDER BY SUM(rs.cantidad) DESC
    LIMIT 1;
END$$

-- 10. Alertar sobre servicios adicionales sin consumo en los últimos 6 meses
DROP EVENT IF EXISTS evt_alertar_servicios_obsoletos$$
CREATE EVENT evt_alertar_servicios_obsoletos
ON SCHEDULE EVERY 1 MONTH
STARTS (CURRENT_DATE + INTERVAL 1 MONTH + INTERVAL 1 HOUR)
DO
BEGIN
    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    SELECT 
        'servicio_adicional',
        'INACTIVE_ALERT',
        CONCAT('AVISO: El servicio "', sa.nombre, '" (ID ', sa.id_servicio, ') no ha tenido demandas en los últimos 6 meses.')
    FROM servicio_adicional sa
    LEFT JOIN reserva_servicio rs ON sa.id_servicio = rs.id_servicio
    LEFT JOIN usuario_servicio us ON sa.id_servicio = us.id_servicio
    WHERE rs.id_reserva_servicio IS NULL AND us.id_usuario_servicio IS NULL;
END$$

-- 11. Aplicar recargo del 5% por mora a facturas pendientes vencidas
DROP EVENT IF EXISTS evt_aplicar_recargos_facturas_vencidas$$
CREATE EVENT evt_aplicar_recargos_facturas_vencidas
ON SCHEDULE EVERY 1 DAY
STARTS (CURRENT_DATE + INTERVAL 1 DAY + INTERVAL 2 HOUR)
DO
BEGIN
    UPDATE factura
    SET recargo = recargo + (monto_total * 0.05),
        saldo_pendiente = saldo_pendiente + (monto_total * 0.05)
    WHERE estado_factura = 'pendiente'
      AND fecha_vencimiento < CURRENT_DATE
      AND recargo = 0.00;
      
    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    VALUES ('factura', 'RECHARGE_EVENT', 'Recargo por mora del 5% aplicado a facturas vencidas.');
END$$

-- 12. Anular automáticamente facturas pendientes con mora superior a 90 días
DROP EVENT IF EXISTS evt_anular_facturas_mora_extrema$$
CREATE EVENT evt_anular_facturas_mora_extrema
ON SCHEDULE EVERY 1 MONTH
STARTS (CURRENT_DATE + INTERVAL 1 MONTH)
DO
BEGIN
    UPDATE factura
    SET estado_factura = 'anulada',
        motivo_anulacion = 'Anulación automática por mora superior a 90 días'
    WHERE estado_factura = 'pendiente'
      AND fecha_vencimiento < (CURRENT_DATE - INTERVAL 90 DAY);
      
    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    VALUES ('factura', 'CANCEL_EVENT', 'Anulación de facturas con mora superior a 90 días.');
END$$

-- 13. Cierre diario de caja: Generar balance de pagos recaudados en el día
DROP EVENT IF EXISTS evt_generar_cierre_caja_diario$$
CREATE EVENT evt_generar_cierre_caja_diario
ON SCHEDULE EVERY 1 DAY
STARTS (CURRENT_DATE + INTERVAL 23 HOUR + INTERVAL 59 MINUTE)
DO
BEGIN
    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    SELECT 
        'pago',
        'DAILY_CLOSING',
        CONCAT('CIERRE CAJA ', CURRENT_DATE, ': Total Recaudado = $', IFNULL(SUM(monto), 0.00), ' en ', COUNT(id_pago), ' transacciones.')
    FROM pago
    WHERE DATE(fecha_pago) = CURRENT_DATE
      AND estado_pago = 'pagado';
END$$

-- 14. Generar consolidado mensual de facturación e ingresos
DROP EVENT IF EXISTS evt_reporte_mensual_ingresos$$
CREATE EVENT evt_reporte_mensual_ingresos
ON SCHEDULE EVERY 1 MONTH
STARTS (CURRENT_DATE + INTERVAL 1 MONTH)
DO
BEGIN
    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    SELECT 
        'factura',
        'MONTHLY_REPORT',
        CONCAT('BALANCE MES ', MONTH(CURRENT_DATE - INTERVAL 1 MONTH), '/', YEAR(CURRENT_DATE - INTERVAL 1 MONTH), 
               ': Total Facturado = $', IFNULL(SUM(monto_total), 0.00), 
               ' | Cobrado = $', IFNULL(SUM(monto_total - saldo_pendiente), 0.00))
    FROM factura
    WHERE fecha_emision >= (CURRENT_DATE - INTERVAL 1 MONTH)
      AND estado_factura != 'anulada';
END$$

-- 15. Cerrar accesos abiertos automáticamente al final de cada jornada (03:00 AM)
DROP EVENT IF EXISTS evt_cerrar_accesos_incompletos$$
CREATE EVENT evt_cerrar_accesos_incompletos
ON SCHEDULE EVERY 1 DAY
STARTS (CURRENT_DATE + INTERVAL 1 DAY + INTERVAL 3 HOUR)
DO
BEGIN
    UPDATE control_acceso
    SET fecha_hora_salida = CONCAT(DATE(fecha_hora_entrada), ' 23:59:59')
    WHERE fecha_hora_salida IS NULL
      AND estado_acceso = 'permitido'
      AND DATE(fecha_hora_entrada) < CURRENT_DATE;
      
    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    VALUES ('control_acceso', 'AUTO_CLOSE_EVENT', 'Cierre automático de registros de acceso sin marcación de salida.');
END$$

-- 16. Depurar registros de auditoría antiguos mayores a 1 año
DROP EVENT IF EXISTS evt_depurar_logs_auditoria_antiguos$$
CREATE EVENT evt_depurar_logs_auditoria_antiguos
ON SCHEDULE EVERY 3 MONTH
STARTS (CURRENT_DATE + INTERVAL 3 MONTH)
DO
BEGIN
    DELETE FROM log_auditoria
    WHERE fecha_hora < (CURRENT_DATE - INTERVAL 1 YEAR);
    
    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    VALUES ('log_auditoria', 'PURGE_EVENT', 'Depuración trimestral de registros de auditoría antiguos.');
END$$

-- 17. Limpiar intentos de acceso rechazados con antigüedad mayor a 6 meses
DROP EVENT IF EXISTS evt_depurar_accesos_rechazados$$
CREATE EVENT evt_depurar_accesos_rechazados
ON SCHEDULE EVERY 1 MONTH
STARTS (CURRENT_DATE + INTERVAL 1 MONTH)
DO
BEGIN
    DELETE FROM control_acceso
    WHERE estado_acceso = 'rechazado'
      AND fecha_hora_entrada < (CURRENT_DATE - INTERVAL 6 MONTH);
      
    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    VALUES ('control_acceso', 'PURGE_EVENT', 'Depuración mensual de logs de accesos rechazados antiguos.');
END$$

-- 18. Registrar métrica de ocupación diaria de las instalaciones
DROP EVENT IF EXISTS evt_resumen_ocupacion_diaria$$
CREATE EVENT evt_resumen_ocupacion_diaria
ON SCHEDULE EVERY 1 DAY
STARTS (CURRENT_DATE + INTERVAL 23 HOUR + INTERVAL 50 MINUTE)
DO
BEGIN
    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    SELECT 
        'espacio',
        'OCCUPANCY_METRIC',
        CONCAT('OCUPACIÓN ', CURRENT_DATE, ': Total Reservas Completadas/Confirmadas = ', COUNT(id_reserva))
    FROM reserva
    WHERE fecha_reserva = CURRENT_DATE
      AND estado_reserva IN ('confirmada', 'completada');
END$$

-- 19. Alerta semanal de usuarios con membresía activa pero sin ingresos en la semana
DROP EVENT IF EXISTS evt_alerta_usuarios_inactivos_semanal$$
CREATE EVENT evt_alerta_usuarios_inactivos_semanal
ON SCHEDULE EVERY 1 WEEK
STARTS (CURRENT_DATE + INTERVAL 1 WEEK)
DO
BEGIN
    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    SELECT 
        'usuario',
        'INACTIVITY_WEEKLY_ALERT',
        CONCAT('AVISO SEMANAL: El usuario ID ', u.id_usuario, ' (', u.primer_nombre, ' ', u.primer_apellido, ') tiene membresía activa pero no registra ingresos esta semana.')
    FROM usuario u
    JOIN membresia m ON u.id_usuario = m.id_usuario AND m.estado = 'activa'
    LEFT JOIN control_acceso ca ON u.id_usuario = ca.id_usuario AND ca.fecha_hora_entrada >= (CURRENT_DATE - INTERVAL 7 DAY)
    WHERE ca.id_acceso IS NULL;
END$$

-- 20. Verificación semanal de estado del Event Scheduler (Heartbeat)
DROP EVENT IF EXISTS evt_heartbeat_scheduler$$
CREATE EVENT evt_heartbeat_scheduler
ON SCHEDULE EVERY 1 WEEK
DO
BEGIN
    INSERT INTO log_auditoria (tabla_afectada, operacion, descripcion)
    VALUES ('SISTEMA', 'HEARTBEAT', 'Verificación semanal de funcionamiento activo del MySQL Event Scheduler.');
END$$

DELIMITER ;
