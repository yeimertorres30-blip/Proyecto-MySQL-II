/*
PROYECTO: Gestión de Coworking y Oficinas Compartidas
MÓDULO: Funciones SQL (fn_)
ARCHIVO: 01_funciones.sql
DESCRIPCIÓN: Implementación de 20 funciones almacenadas personalizadas (DETERMINISTIC / READS SQL DATA)
             para el cálculo de métricas, estadísticas, validación de estados e indicadores
             de usuarios, membresías, reservas, facturación y accesos.
*/

USE coworking_db;

-- Eliminar funciones existentes para permitir reejecución limpia
DROP FUNCTION IF EXISTS fn_membresia_activa;
DROP FUNCTION IF EXISTS fn_dias_restantes_membresia;
DROP FUNCTION IF EXISTS fn_tipo_membresia_usuario;
DROP FUNCTION IF EXISTS fn_conteo_renovaciones_usuario;

DROP FUNCTION IF EXISTS fn_total_reservas_usuario;
DROP FUNCTION IF EXISTS fn_reservas_activas_usuario;
DROP FUNCTION IF EXISTS fn_horas_reservadas_mes;
DROP FUNCTION IF EXISTS fn_espacio_mas_reservado_usuario;

DROP FUNCTION IF EXISTS fn_total_gasto_servicios_usuario;
DROP FUNCTION IF EXISTS fn_servicio_mas_vendido_mes;
DROP FUNCTION IF EXISTS fn_cantidad_servicios_reserva;

DROP FUNCTION IF EXISTS fn_total_pagado_usuario;
DROP FUNCTION IF EXISTS fn_saldo_pendiente_usuario;
DROP FUNCTION IF EXISTS fn_ingresos_mensuales_totales;
DROP FUNCTION IF EXISTS fn_ingresos_empresa_corporativa;

DROP FUNCTION IF EXISTS fn_total_asistencias_usuario;
DROP FUNCTION IF EXISTS fn_asistencias_mes_usuario;
DROP FUNCTION IF EXISTS fn_ultima_fecha_ingreso;
DROP FUNCTION IF EXISTS fn_promedio_permanencia_horas;
DROP FUNCTION IF EXISTS fn_usuario_mas_frecuente_mes;

DELIMITER $$

-- 1. Verifica si un usuario posee actualmente una membresía activa
CREATE FUNCTION fn_membresia_activa(p_id_usuario INT)
RETURNS TINYINT(1)
READS SQL DATA
BEGIN
    DECLARE v_activa INT DEFAULT 0;
    SELECT COUNT(*) INTO v_activa
    FROM membresia
    WHERE id_usuario = p_id_usuario
      AND estado = 'activa'
      AND fecha_vencimiento >= CURRENT_DATE();
    
    RETURN IF(v_activa > 0, 1, 0);
END $$

-- 2. Calcula los días restantes de la membresía activa de un usuario
CREATE FUNCTION fn_dias_restantes_membresia(p_id_usuario INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_dias INT DEFAULT 0;
    SELECT IFNULL(DATEDIFF(MAX(fecha_vencimiento), CURRENT_DATE()), 0) INTO v_dias
    FROM membresia
    WHERE id_usuario = p_id_usuario
      AND estado = 'activa'
      AND fecha_vencimiento >= CURRENT_DATE();
    
    RETURN IF(v_dias < 0, 0, v_dias);
END $$

-- 3. Retorna el nombre del plan de membresía activa actual de un usuario
CREATE FUNCTION fn_tipo_membresia_usuario(p_id_usuario INT)
RETURNS VARCHAR(50)
READS SQL DATA
BEGIN
    DECLARE v_nombre_plan VARCHAR(50) DEFAULT 'Sin Membresía';
    SELECT tm.nombre INTO v_nombre_plan
    FROM membresia m
    JOIN tipo_membresia tm ON m.id_tipo_membresia = tm.id_tipo_membresia
    WHERE m.id_usuario = p_id_usuario
      AND m.estado = 'activa'
      AND m.fecha_vencimiento >= CURRENT_DATE()
    ORDER BY m.fecha_vencimiento DESC
    LIMIT 1;
    
    RETURN IFNULL(v_nombre_plan, 'Sin Membresía');
END $$

-- 4. Cuenta el número histórico total de renovaciones o suscripciones de un usuario
CREATE FUNCTION fn_conteo_renovaciones_usuario(p_id_usuario INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_conteo INT DEFAULT 0;
    SELECT COUNT(*) INTO v_conteo
    FROM membresia
    WHERE id_usuario = p_id_usuario;
    
    RETURN IFNULL(v_conteo, 0);
END $$

-- 5. Calcula el número total de reservas realizadas por un usuario
CREATE FUNCTION fn_total_reservas_usuario(p_id_usuario INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_total INT DEFAULT 0;
    SELECT COUNT(*) INTO v_total
    FROM reserva
    WHERE id_usuario = p_id_usuario;
    
    RETURN IFNULL(v_total, 0);
END $$

-- 6. Obtiene la cantidad de reservas vigentes (confirmadas o pendientes) de un usuario
CREATE FUNCTION fn_reservas_activas_usuario(p_id_usuario INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_activas INT DEFAULT 0;
    SELECT COUNT(*) INTO v_activas
    FROM reserva
    WHERE id_usuario = p_id_usuario
      AND estado_reserva IN ('pendiente', 'confirmada')
      AND fecha_reserva >= CURRENT_DATE();
    
    RETURN IFNULL(v_activas, 0);
END $$

-- 7. Calcula el acumulado de horas reservadas por un usuario en un mes y año específicos
CREATE FUNCTION fn_horas_reservadas_mes(
    p_id_usuario INT, 
    p_mes INT, 
    p_año INT
) 
RETURNS DECIMAL(10,2) 
READS SQL DATA 
BEGIN 
    DECLARE v_horas DECIMAL(10,2) DEFAULT 0.00; 

    -- Validación de rango para el parámetro del mes (1 a 12) 
    IF p_mes IS NULL OR p_mes < 1 OR p_mes > 12 THEN 
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: El mes ingresado no es válido. Debe ser un valor numérico entre 1 y 12.'; 
    END IF; 

    SELECT IFNULL(SUM(TIMESTAMPDIFF(MINUTE, reserva.hora_inicio, reserva.hora_fin) / 60.0), 0.00) INTO v_horas 
    FROM reserva 
    WHERE reserva.id_usuario = p_id_usuario 
      AND reserva.estado_reserva IN ('confirmada', 'completada') 
      AND MONTH(reserva.fecha_reserva) = p_mes 
      AND YEAR(reserva.fecha_reserva) = p_año; 

    RETURN v_horas; 
END $$

-- 8. Identifica el código del espacio más reservado por un usuario específico
CREATE FUNCTION fn_espacio_mas_reservado_usuario(p_id_usuario INT)
RETURNS VARCHAR(50)
READS SQL DATA
BEGIN
    DECLARE v_codigo VARCHAR(50) DEFAULT 'Ninguno';
    SELECT e.codigo_espacio INTO v_codigo
    FROM reserva r
    JOIN espacio e ON r.id_espacio = e.id_espacio
    WHERE r.id_usuario = p_id_usuario
    GROUP BY e.id_espacio, e.codigo_espacio
    ORDER BY COUNT(*) DESC
    LIMIT 1;
    
    RETURN IFNULL(v_codigo, 'Ninguno');
END $$

-- 9. Suma el total gastado por un usuario en servicios adicionales (vía reserva o directo)
CREATE FUNCTION fn_total_gasto_servicios_usuario(p_id_usuario INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE v_gasto_reserva DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_gasto_directo DECIMAL(10,2) DEFAULT 0.00;
    
    SELECT IFNULL(SUM(rs.sub_total), 0.00) INTO v_gasto_reserva
    FROM reserva_servicio rs
    JOIN reserva r ON rs.id_reserva = r.id_reserva
    WHERE r.id_usuario = p_id_usuario;
    
    SELECT IFNULL(SUM(sub_total), 0.00) INTO v_gasto_directo
    FROM usuario_servicio
    WHERE id_usuario = p_id_usuario;
    
    RETURN v_gasto_reserva + v_gasto_directo;
END $$

-- 10. Retorna el nombre del servicio adicional más contratado en un mes/año
CREATE FUNCTION fn_servicio_mas_vendido_mes(
    p_mes INT, 
    p_año INT
) 
RETURNS VARCHAR(100) 
READS SQL DATA 
BEGIN 
    DECLARE v_nombre VARCHAR(100) DEFAULT 'Sin Ventas'; 

    -- Validación de rango para el parámetro del mes (1 a 12) 
    IF p_mes IS NULL OR p_mes < 1 OR p_mes > 12 THEN 
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: El mes ingresado no es válido. Debe ser un valor numérico entre 1 y 12.'; 
    END IF; 

    SELECT servicio_adicional.nombre INTO v_nombre 
    FROM (
        SELECT 
            t.id_servicio, 
            SUM(t.cantidad) AS total_cant 
        FROM (
            SELECT 
                reserva_servicio.id_servicio, 
                reserva_servicio.cantidad 
            FROM reserva_servicio 
            INNER JOIN reserva ON reserva_servicio.id_reserva = reserva.id_reserva 
            WHERE MONTH(reserva.fecha_reserva) = p_mes 
              AND YEAR(reserva.fecha_reserva) = p_año 
            
            UNION ALL 
            
            SELECT 
                usuario_servicio.id_servicio, 
                usuario_servicio.cantidad 
            FROM usuario_servicio 
            WHERE MONTH(usuario_servicio.fecha_contratacion) = p_mes 
              AND YEAR(usuario_servicio.fecha_contratacion) = p_año
        ) AS t 
        GROUP BY t.id_servicio 
        ORDER BY total_cant DESC 
        LIMIT 1
    ) AS res 
    INNER JOIN servicio_adicional ON res.id_servicio = servicio_adicional.id_servicio; 

    RETURN IFNULL(v_nombre, 'Sin Ventas'); 
END $$

-- 11. Calcula la cantidad total de unidades de servicios agregados a una reserva
CREATE FUNCTION fn_cantidad_servicios_reserva(p_id_reserva INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_cantidad INT DEFAULT 0;
    SELECT IFNULL(SUM(cantidad), 0) INTO v_cantidad
    FROM reserva_servicio
    WHERE id_reserva = p_id_reserva;
    
    RETURN v_cantidad;
END $$

-- 12. Calcula el monto histórico total pagado en efectivo/tarjeta por un usuario
CREATE FUNCTION fn_total_pagado_usuario(p_id_usuario INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(10,2) DEFAULT 0.00;
    SELECT IFNULL(SUM(monto), 0.00) INTO v_total
    FROM pago
    WHERE id_usuario = p_id_usuario
      AND estado_pago = 'pagado';
    
    RETURN v_total;
END $$

-- 13. Obtiene el saldo total pendiente de cobro en facturas de un usuario
CREATE FUNCTION fn_saldo_pendiente_usuario(p_id_usuario INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE v_saldo DECIMAL(10,2) DEFAULT 0.00;
    SELECT IFNULL(SUM(saldo_pendiente), 0.00) INTO v_saldo
    FROM factura
    WHERE id_usuario = p_id_usuario
      AND estado_factura = 'pendiente';
    
    RETURN v_saldo;
END $$

-- 14. Calcula el total de ingresos recaudados por pagos en un mes y año específicos
CREATE FUNCTION fn_ingresos_mensuales_totales(
    p_mes INT, 
    p_año INT
)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE v_ingresos DECIMAL(10,2) DEFAULT 0.00;

    -- Validación para restringir el parámetro del mes (1 a 12)
    IF p_mes IS NULL OR p_mes < 1 OR p_mes > 12 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El mes ingresado no es válido. Debe ser un valor numérico entre 1 y 12.';
    END IF;

    SELECT IFNULL(SUM(pago.monto), 0.00) INTO v_ingresos
    FROM pago
    WHERE pago.estado_pago = 'pagado'
      AND MONTH(pago.fecha_pago) = p_mes
      AND YEAR(pago.fecha_pago) = p_año;

    RETURN v_ingresos;
END $$

-- 15. Consolida los ingresos generados por los empleados asociados a una empresa corporativa
CREATE FUNCTION fn_ingresos_empresa_corporativa(p_id_empresa INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE v_ingresos DECIMAL(10,2) DEFAULT 0.00;
    SELECT IFNULL(SUM(p.monto), 0.00) INTO v_ingresos
    FROM pago p
    JOIN usuario u ON p.id_usuario = u.id_usuario
    WHERE u.id_empresa = p_id_empresa
      AND p.estado_pago = 'pagado';
    
    RETURN v_ingresos;
END $$


-- 16. Cuenta el total de accesos permitidos registrados por un usuario
CREATE FUNCTION fn_total_asistencias_usuario(p_id_usuario INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_total INT DEFAULT 0;
    SELECT COUNT(*) INTO v_total
    FROM control_acceso
    WHERE id_usuario = p_id_usuario
      AND estado_acceso = 'permitido';
    
    RETURN IFNULL(v_total, 0);
END $$

-- 17. Calcula el total de check-ins exitosos de un usuario en un mes y año dados
CREATE FUNCTION fn_asistencias_mes_usuario(
    p_id_usuario INT, 
    p_mes INT, 
    p_año INT
) 
RETURNS INT 
READS SQL DATA 
BEGIN 
    DECLARE v_asistencias INT DEFAULT 0; 

    -- Validación para restringir el parámetro del mes (1 a 12) 
    IF p_mes IS NULL OR p_mes < 1 OR p_mes > 12 THEN 
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: El mes ingresado no es válido. Debe ser un valor numérico entre 1 y 12.'; 
    END IF; 

    SELECT COUNT(*) INTO v_asistencias 
    FROM control_acceso 
    WHERE control_acceso.id_usuario = p_id_usuario 
      AND control_acceso.estado_acceso = 'permitido' 
      AND MONTH(control_acceso.fecha_hora_entrada) = p_mes 
      AND YEAR(control_acceso.fecha_hora_entrada) = p_año; 

    RETURN IFNULL(v_asistencias, 0); 
END $$

-- 18. Retorna la fecha y hora del último acceso registrado permitido de un usuario
CREATE FUNCTION fn_ultima_fecha_ingreso(p_id_usuario INT)
RETURNS DATETIME
READS SQL DATA
BEGIN
    DECLARE v_fecha DATETIME;
    SELECT MAX(fecha_hora_entrada) INTO v_fecha
    FROM control_acceso
    WHERE id_usuario = p_id_usuario
      AND estado_acceso = 'permitido';
    
    RETURN v_fecha;
END $$

-- 19. Calcula el promedio de horas de permanencia por visita de un usuario
CREATE FUNCTION fn_promedio_permanencia_horas(p_id_usuario INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE v_promedio DECIMAL(10,2) DEFAULT 0.00;
    SELECT IFNULL(AVG(TIMESTAMPDIFF(MINUTE, fecha_hora_entrada, fecha_hora_salida) / 60.0), 0.00) INTO v_promedio
    FROM control_acceso
    WHERE id_usuario = p_id_usuario
      AND estado_acceso = 'permitido'
      AND fecha_hora_salida IS NOT NULL;
    
    RETURN v_promedio;
END $$

-- 20. Devuelve el nombre completo del usuario con mayor cantidad de asistencias en un mes
CREATE FUNCTION fn_usuario_mas_frecuente_mes(
    p_mes INT, 
    p_año INT
) 
RETURNS VARCHAR(150) 
READS SQL DATA 
BEGIN 
    DECLARE v_nombre_completo VARCHAR(150) DEFAULT 'Ninguno'; 

    -- Validación para restringir el parámetro del mes (1 a 12) 
    IF p_mes IS NULL OR p_mes < 1 OR p_mes > 12 THEN 
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: El mes ingresado no es válido. Debe ser un valor numérico entre 1 y 12.'; 
    END IF; 

    SELECT CONCAT(usuario.primer_nombre, ' ', usuario.primer_apellido) INTO v_nombre_completo 
    FROM control_acceso 
    INNER JOIN usuario ON control_acceso.id_usuario = usuario.id_usuario 
    WHERE control_acceso.estado_acceso = 'permitido' 
      AND MONTH(control_acceso.fecha_hora_entrada) = p_mes 
      AND YEAR(control_acceso.fecha_hora_entrada) = p_año 
    GROUP BY 
        usuario.id_usuario, 
        usuario.primer_nombre, 
        usuario.primer_apellido 
    ORDER BY COUNT(*) DESC 
    LIMIT 1; 

    RETURN IFNULL(v_nombre_completo, 'Ninguno'); 
END $$