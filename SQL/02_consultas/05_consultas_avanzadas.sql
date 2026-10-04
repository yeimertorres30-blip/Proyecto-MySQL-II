-- MÓDULO: Consultas Avanzadas
-- CONSULTA 81: Mostrar los usuarios con el mayor gasto acumulado (subconsulta con SUM).
-- Hecho por Exneider Nava

USE coworking_db;

SELECT 
    usuario.id_usuario,
    usuario.tipo_documento,
    usuario.numero_documento,
    CONCAT(usuario.primer_nombre, ' ', IFNULL(usuario.segundo_nombre, ''), ' ', usuario.primer_apellido) AS nombre_completo,
    usuario.email,
    SUM(pago.monto) AS gasto_acumulado
FROM usuario
INNER JOIN pago ON usuario.id_usuario = pago.id_usuario
WHERE pago.estado_pago = 'pagado'
GROUP BY 
    usuario.id_usuario, 
    usuario.tipo_documento, 
    usuario.numero_documento, 
    usuario.primer_nombre, 
    usuario.segundo_nombre, 
    usuario.primer_apellido, 
    usuario.email
HAVING SUM(pago.monto) = (
    SELECT MAX(sub.total_gastado)
    FROM (
        SELECT SUM(p2.monto) AS total_gastado
        FROM pago p2
        WHERE p2.estado_pago = 'pagado'
        GROUP BY p2.id_usuario
    ) AS sub
);

-- CONSULTA 82:  Mostrar los espacios más ocupados considerando reservas confirmadas y asistencias reales. 
-- Hecho por Exneider Nava 


SELECT 
    espacio.id_espacio, 
    espacio.codigo_espacio, 
    tipo_espacio.nombre AS tipo_espacio, 
    espacio.capacidad_maxima, 
    espacio.precio_por_hora, 
    COUNT(DISTINCT reserva.id_reserva) AS total_reservas_efectivas, 
    COUNT(DISTINCT control_acceso.id_acceso) AS total_asistencias_reales, 
    (COUNT(DISTINCT reserva.id_reserva) + COUNT(DISTINCT control_acceso.id_acceso)) AS indice_ocupacion_total 
FROM espacio 
INNER JOIN tipo_espacio ON espacio.id_tipo_espacio = tipo_espacio.id_tipo_espacio 
LEFT JOIN reserva ON espacio.id_espacio = reserva.id_espacio 
    AND reserva.estado_reserva IN ('confirmada', 'completada') 
LEFT JOIN control_acceso ON reserva.id_reserva = control_acceso.id_reserva 
    AND control_acceso.estado_acceso = 'permitido' 
GROUP BY 
    espacio.id_espacio, 
    espacio.codigo_espacio, 
    tipo_espacio.nombre, 
    espacio.capacidad_maxima, 
    espacio.precio_por_hora 
ORDER BY 
    indice_ocupacion_total DESC, 
    total_asistencias_reales DESC;
    
-- CONSULTA 83: Calcular el promedio de ingresos por usuario usando subconsultas.
-- Creado por Exneider Nava 


SELECT 
    ROUND(AVG(ingresos_usuario.total_pagado), 2) AS promedio_ingresos_por_usuario 
FROM (
    SELECT 
        usuario.id_usuario, 
        IFNULL(SUM(pago.monto), 0) AS total_pagado 
    FROM usuario 
    LEFT JOIN pago ON usuario.id_usuario = pago.id_usuario 
        AND pago.estado_pago = 'pagado' 
    GROUP BY usuario.id_usuario
) AS ingresos_usuario;

-- CONSULTA 84: Listar usuarios que tienen reservas activas y facturas pendientes. 
-- Creado por Exneider Nava


SELECT 
    usuario.id_usuario, 
    usuario.tipo_documento, 
    usuario.numero_documento, 
    CONCAT(
        usuario.primer_nombre, 
        IF(usuario.segundo_nombre IS NOT NULL AND usuario.segundo_nombre <> '', CONCAT(' ', usuario.segundo_nombre), ''), 
        ' ', 
        usuario.primer_apellido, 
        IF(usuario.segundo_apellido IS NOT NULL AND usuario.segundo_apellido <> '', CONCAT(' ', usuario.segundo_apellido), '')
    ) AS nombre_completo, 
    usuario.email, 
    usuario.telefono, 
    r_sub.total_reservas_activas, 
    f_sub.total_facturas_pendientes, 
    f_sub.total_deuda_pendiente 
FROM usuario 
INNER JOIN (
    SELECT 
        id_usuario, 
        COUNT(*) AS total_reservas_activas 
    FROM reserva 
    WHERE estado_reserva IN ('completada', 'cancelada') 
    GROUP BY id_usuario
) r_sub ON usuario.id_usuario = r_sub.id_usuario 
INNER JOIN (
    SELECT 
        id_usuario, 
        COUNT(*) AS total_facturas_pendientes, 
        SUM(saldo_pendiente) AS total_deuda_pendiente 
    FROM factura 
    WHERE estado_factura = 'pendiente' 
    GROUP BY id_usuario
) f_sub ON usuario.id_usuario = f_sub.id_usuario 
ORDER BY f_sub.total_deuda_pendiente DESC;

-- CONSULTA 85: Mostrar empresas cuyos empleados generan más del 20% de los ingresos totales. 
-- Creado por Exneider Nava.  

SELECT 
    empresa.id_empresa, 
    empresa.razon_social, 
    empresa.nit_ruc, 
    SUM(factura.monto_total) AS ingresos_totales_empresa, 
    ROUND(
        (SUM(factura.monto_total) * 100.0 / (
            SELECT SUM(factura.monto_total) 
            FROM factura 
            WHERE factura.estado_factura = 'pagada'
        )), 2
    ) AS porcentaje_ingresos 
FROM empresa 
INNER JOIN usuario ON empresa.id_empresa = usuario.id_empresa 
INNER JOIN factura ON usuario.id_usuario = factura.id_usuario 
WHERE factura.estado_factura = 'pagada' 
GROUP BY 
    empresa.id_empresa, 
    empresa.razon_social, 
    empresa.nit_ruc 
HAVING SUM(factura.monto_total) > (
    SELECT SUM(factura.monto_total) * 0.20 
    FROM factura 
    WHERE factura.estado_factura = 'pagada'
) 
ORDER BY ingresos_totales_empresa DESC;

-- CONSULTA 86: Mostrar el top 5 de usuarios que más usan servicios adicionales. 
-- Creado por Exneider Nava 


SELECT 
    usuario.id_usuario, 
    usuario.tipo_documento, 
    usuario.numero_documento, 
    CONCAT(
        usuario.primer_nombre, 
        IF(usuario.segundo_nombre IS NOT NULL AND usuario.segundo_nombre <> '', CONCAT(' ', usuario.segundo_nombre), ''), 
        ' ', 
        usuario.primer_apellido, 
        IF(usuario.segundo_apellido IS NOT NULL AND usuario.segundo_apellido <> '', CONCAT(' ', usuario.segundo_apellido), '')
    ) AS nombre_completo, 
    usuario.email, 
    SUM(servicios_totales.cantidad_servicios) AS total_unidades_servicios, 
    SUM(servicios_totales.monto_total_servicios) AS total_gasto_servicios 
FROM usuario 
INNER JOIN (
    SELECT 
        reserva.id_usuario AS id_usuario, 
        SUM(reserva_servicio.cantidad) AS cantidad_servicios, 
        SUM(reserva_servicio.cantidad * reserva_servicio.precio_aplicado) AS monto_total_servicios 
    FROM reserva_servicio 
    INNER JOIN reserva ON reserva_servicio.id_reserva = reserva.id_reserva 
    GROUP BY reserva.id_usuario 
    UNION ALL 
    SELECT 
        usuario_servicio.id_usuario AS id_usuario, 
        SUM(usuario_servicio.cantidad) AS cantidad_servicios, 
        SUM(usuario_servicio.cantidad * usuario_servicio.precio_aplicado) AS monto_total_servicios 
    FROM usuario_servicio 
    GROUP BY usuario_servicio.id_usuario
) AS servicios_totales ON usuario.id_usuario = servicios_totales.id_usuario 
GROUP BY 
    usuario.id_usuario, 
    usuario.tipo_documento, 
    usuario.numero_documento, 
    usuario.primer_nombre, 
    usuario.segundo_nombre, 
    usuario.primer_apellido, 
    usuario.segundo_apellido, 
    usuario.email 
ORDER BY 
    total_unidades_servicios DESC, 
    total_gasto_servicios DESC 
LIMIT 5;

-- CONSULTA 87: Mostrar reservas que generaron facturas mayores al promedio. 
-- Hecho por Exneider Nava

SELECT 
    reserva.id_reserva, 
    reserva.fecha_reserva, 
    reserva.hora_inicio, 
    reserva.hora_fin, 
    reserva.estado_reserva, 
    CONCAT(
        usuario.primer_nombre, 
        IF(usuario.segundo_nombre IS NOT NULL AND usuario.segundo_nombre <> '', CONCAT(' ', usuario.segundo_nombre), ''), 
        ' ', 
        usuario.primer_apellido
    ) AS cliente, 
    espacio.codigo_espacio, 
    factura.id_factura, 
    factura.monto_total AS monto_factura, 
    ROUND((SELECT AVG(factura.monto_total) FROM factura), 2) AS promedio_general_facturas 
FROM reserva 
INNER JOIN usuario ON reserva.id_usuario = usuario.id_usuario 
INNER JOIN espacio ON reserva.id_espacio = espacio.id_espacio 
INNER JOIN detalle_factura ON reserva.id_reserva = detalle_factura.id_reserva 
INNER JOIN factura ON detalle_factura.id_factura = factura.id_factura 
WHERE factura.monto_total > (
    SELECT AVG(factura.monto_total) 
    FROM factura
) 
ORDER BY 
    factura.monto_total DESC, 
    reserva.id_reserva ASC;
    
-- CONSULTA 88: Calcular el porcentaje de ocupación global del coworking por mes. 
-- Hecho por Exneider Nava.

SELECT 
    reserva.fecha_reserva AS mes_año, 
    COUNT(reserva.id_reserva) AS total_reservas_solicitadas, 
    SUM(
        CASE 
            WHEN reserva.estado_reserva IN ('confirmada', 'completada') THEN 1 
            ELSE 0 
        END
    ) AS reservas_efectivas, 
    SUM(
        CASE 
            WHEN reserva.estado_reserva IN ('confirmada', 'completada') THEN TIMESTAMPDIFF(HOUR, reserva.hora_inicio, reserva.hora_fin) 
            ELSE 0 
        END
    ) AS total_horas_ocupadas, 
    (
        (SELECT COUNT(*) FROM espacio WHERE espacio.estado_disponibilidad <> 'mantenimiento') * 8 * DAY(LAST_DAY(reserva.fecha_reserva))
    ) AS capacidad_horas_mes, 
    ROUND(
        (
            SUM(
                CASE 
                    WHEN reserva.estado_reserva IN ('cancelada', 'completada') THEN TIMESTAMPDIFF(HOUR, reserva.hora_inicio, reserva.hora_fin) 
                    ELSE 0 
                END
            ) * 100.0
        ) / (
            (SELECT COUNT(*) FROM espacio WHERE espacio.estado_disponibilidad <> 'mantenimiento') * 8 * DAY(LAST_DAY(reserva.fecha_reserva))
        ), 2
    ) AS porcentaje_ocupacion_global 
FROM reserva 
INNER JOIN espacio ON reserva.id_espacio = espacio.id_espacio 
GROUP BY 
    reserva.fecha_reserva, 
    LAST_DAY(reserva.fecha_reserva) 
ORDER BY mes_año ASC;

-- CONSULTA 89: Mostrar usuarios que tienen más horas de reserva que el promedio del sistema. 
-- Hecho por Exneider Nava 

SELECT 
    usuario.id_usuario, 
    usuario.tipo_documento, 
    usuario.numero_documento, 
    CONCAT(
        usuario.primer_nombre, 
        IF(usuario.segundo_nombre IS NOT NULL AND usuario.segundo_nombre <> '', CONCAT(' ', usuario.segundo_nombre), ''), 
        ' ', 
        usuario.primer_apellido, 
        IF(usuario.segundo_apellido IS NOT NULL AND usuario.segundo_apellido <> '', CONCAT(' ', usuario.segundo_apellido), '')
    ) AS nombre_completo, 
    usuario.email, 
    usuario.telefono, 
    SUM(TIMESTAMPDIFF(HOUR, reserva.hora_inicio, reserva.hora_fin)) AS total_horas_reservadas, 
    ROUND(
        (
            SELECT AVG(subconsulta_horas.total_horas_usuario) 
            FROM (
                SELECT SUM(TIMESTAMPDIFF(HOUR, reserva.hora_inicio, reserva.hora_fin)) AS total_horas_usuario 
                FROM reserva 
                WHERE reserva.estado_reserva IN ('cancelada', 'completada') 
                GROUP BY reserva.id_usuario
            ) AS subconsulta_horas
        ), 2
    ) AS promedio_horas_sistema 
FROM usuario 
INNER JOIN reserva ON usuario.id_usuario = reserva.id_usuario 
WHERE reserva.estado_reserva IN ('cancelada', 'completada') 
GROUP BY 
    usuario.id_usuario, 
    usuario.tipo_documento, 
    usuario.numero_documento, 
    usuario.primer_nombre, 
    usuario.segundo_nombre, 
    usuario.primer_apellido, 
    usuario.segundo_apellido, 
    usuario.email, 
    usuario.telefono 
HAVING SUM(TIMESTAMPDIFF(HOUR, reserva.hora_inicio, reserva.hora_fin)) > (
    SELECT AVG(subconsulta_horas.total_horas_usuario) 
    FROM (
        SELECT SUM(TIMESTAMPDIFF(HOUR, reserva.hora_inicio, reserva.hora_fin)) AS total_horas_usuario 
        FROM reserva 
        WHERE reserva.estado_reserva IN ('cancelada', 'completada') 
        GROUP BY reserva.id_usuario
    ) AS subconsulta_horas
) 
ORDER BY total_horas_reservadas DESC;

-- CONSULTA 90: Mostrar el top 3 de salas más usadas en el último trimestre. 
-- Hecho por Exneider Nava 

SELECT 
    espacio.id_espacio, 
    espacio.codigo_espacio, 
    tipo_espacio.nombre AS tipo_espacio, 
    espacio.capacidad_maxima, 
    espacio.precio_por_hora, 
    COUNT(reserva.id_reserva) AS total_reservas, 
    SUM(TIMESTAMPDIFF(HOUR, reserva.hora_inicio, reserva.hora_fin)) AS total_horas_uso 
FROM espacio 
INNER JOIN tipo_espacio ON espacio.id_tipo_espacio = tipo_espacio.id_tipo_espacio 
INNER JOIN reserva ON espacio.id_espacio = reserva.id_espacio 
WHERE tipo_espacio.nombre LIKE '%Sala%' 
  AND reserva.estado_reserva IN ('cancelada', 'completada') 
  -- esta linea de abajo se debe borrar si quiere que muestre resultados
  -- porque los datos actuales no arrojan el trimestre
  AND reserva.fecha_reserva >= DATE_SUB(CURRENT_DATE(), INTERVAL 3 MONTH) 
GROUP BY 
    espacio.id_espacio, 
    espacio.codigo_espacio, 
    tipo_espacio.nombre, 
    espacio.capacidad_maxima, 
    espacio.precio_por_hora 
ORDER BY 
    total_reservas DESC, 
    total_horas_uso DESC 
LIMIT 3;

-- CONSULTA 91: Calcular ingresos promedio por tipo de membresía (agrupado con AVG). 
-- Hecho por Exneider Nava

SELECT 
    tipo_membresia.id_tipo_membresia, 
    tipo_membresia.nombre AS tipo_membresia, 
    tipo_membresia.precio_base, 
    COUNT(membresia.id_membresia) AS total_membresias_vendidas, 
    ROUND(AVG(membresia.precio_cobrado), 2) AS ingreso_promedio_membresia, 
    ROUND(SUM(membresia.precio_cobrado), 2) AS ingreso_total_acumulado 
FROM tipo_membresia 
INNER JOIN membresia ON tipo_membresia.id_tipo_membresia = membresia.id_tipo_membresia 
GROUP BY 
    tipo_membresia.id_tipo_membresia, 
    tipo_membresia.nombre, 
    tipo_membresia.precio_base 
ORDER BY ingreso_promedio_membresia DESC;

-- CONSULTA 92: Mostrar usuarios que pagan solo con un método de pago. 
-- Hecho por Exneider Nava. 

SELECT 
    usuario.id_usuario, 
    usuario.tipo_documento, 
    usuario.numero_documento, 
    CONCAT(
        usuario.primer_nombre, 
        IF(usuario.segundo_nombre IS NOT NULL AND usuario.segundo_nombre <> '', CONCAT(' ', usuario.segundo_nombre), ''), 
        ' ', 
        usuario.primer_apellido, 
        IF(usuario.segundo_apellido IS NOT NULL AND usuario.segundo_apellido <> '', CONCAT(' ', usuario.segundo_apellido), '')
    ) AS nombre_completo, 
    usuario.email, 
    usuario.telefono 
FROM usuario 
WHERE usuario.id_usuario IN (
    SELECT pago.id_usuario 
    FROM pago 
    WHERE pago.estado_pago = 'pagado' 
    GROUP BY pago.id_usuario 
    HAVING COUNT(DISTINCT pago.metodo_pago) = 1
) 
ORDER BY usuario.id_usuario ASC;

-- CONSULTA 93: Mostrar reservas canceladas por usuarios que nunca asistieron. 
-- Hecho por Exneider Nava. 

SELECT 
    reserva.id_reserva, 
    reserva.fecha_reserva, 
    reserva.hora_inicio, 
    reserva.hora_fin, 
    reserva.estado_reserva, 
    usuario.id_usuario, 
    usuario.tipo_documento, 
    usuario.numero_documento, 
    CONCAT(
        usuario.primer_nombre, 
        IF(usuario.segundo_nombre IS NOT NULL AND usuario.segundo_nombre <> '', CONCAT(' ', usuario.segundo_nombre), ''), 
        ' ', 
        usuario.primer_apellido, 
        IF(usuario.segundo_apellido IS NOT NULL AND usuario.segundo_apellido <> '', CONCAT(' ', usuario.segundo_apellido), '')
    ) AS nombre_completo, 
    usuario.email, 
    usuario.telefono, 
    espacio.codigo_espacio 
FROM reserva 
INNER JOIN usuario ON reserva.id_usuario = usuario.id_usuario 
INNER JOIN espacio ON reserva.id_espacio = espacio.id_espacio 
WHERE reserva.estado_reserva = 'cancelada' 
  AND NOT EXISTS (
      SELECT 1 
      FROM control_acceso 
      WHERE control_acceso.id_usuario = usuario.id_usuario 
        AND control_acceso.estado_acceso = 'permitido'
  ) 
ORDER BY 
    reserva.fecha_reserva DESC, 
    reserva.id_reserva ASC;
    
-- CONSULTA 94: Mostrar facturas con pagos parciales y calcular saldo pendiente. 
-- Hecho por Exneider Nava. 

SELECT 
    factura.id_factura, 
    factura.fecha_emision, 
    factura.fecha_vencimiento, 
    factura.estado_factura, 
    usuario.id_usuario, 
    usuario.tipo_documento, 
    usuario.numero_documento, 
    CONCAT(
        usuario.primer_nombre, 
        IF(usuario.segundo_nombre IS NOT NULL AND usuario.segundo_nombre <> '', CONCAT(' ', usuario.segundo_nombre), ''), 
        ' ', 
        usuario.primer_apellido, 
        IF(usuario.segundo_apellido IS NOT NULL AND usuario.segundo_apellido <> '', CONCAT(' ', usuario.segundo_apellido), '')
    ) AS nombre_completo, 
    factura.monto_total, 
    IFNULL(SUM(CASE WHEN pago.estado_pago = 'pagado' THEN pago.monto ELSE 0 END), 0) AS total_abonado, 
    (factura.monto_total + IFNULL(factura.recargo, 0) - IFNULL(SUM(CASE WHEN pago.estado_pago = 'pagado' THEN pago.monto ELSE 0 END), 0)) AS saldo_pendiente_calculado 
FROM factura 
INNER JOIN usuario ON factura.id_usuario = usuario.id_usuario 
LEFT JOIN pago ON factura.id_factura = pago.id_factura 
GROUP BY 
    factura.id_factura, 
    factura.fecha_emision, 
    factura.fecha_vencimiento, 
    factura.estado_factura, 
    usuario.id_usuario, 
    usuario.tipo_documento, 
    usuario.numero_documento, 
    usuario.primer_nombre, 
    usuario.segundo_nombre, 
    usuario.primer_apellido, 
    usuario.segundo_apellido, 
    factura.monto_total, 
    factura.recargo 
HAVING total_abonado > 0 
   AND total_abonado < (factura.monto_total + IFNULL(factura.recargo, 0)) 
ORDER BY saldo_pendiente_calculado DESC;

-- CONSULTA 95: Calcular la facturación total de cada empresa y ordenarla de mayor a menor. 
-- Hecho por Exneider Nava. 

SELECT 
    empresa.id_empresa, 
    empresa.razon_social, 
    empresa.nit_ruc, 
    empresa.email, 
    COUNT(factura.id_factura) AS total_facturas_emitidas, 
    IFNULL(SUM(factura.monto_total), 0.00) AS facturacion_total 
FROM empresa 
INNER JOIN factura ON empresa.id_empresa = factura.id_empresa 
GROUP BY 
    empresa.id_empresa, 
    empresa.razon_social, 
    empresa.nit_ruc, 
    empresa.email 
ORDER BY facturacion_total DESC;

-- CONSULTA 96: Identificar usuarios que superan en reservas al promedio de su empresa. 
-- Hecho por Exneider Nava. 

SELECT 
    usuario.id_usuario, 
    usuario.tipo_documento, 
    usuario.numero_documento, 
    CONCAT(
        usuario.primer_nombre, 
        IF(usuario.segundo_nombre IS NOT NULL AND usuario.segundo_nombre <> '', CONCAT(' ', usuario.segundo_nombre), ''), 
        ' ', 
        usuario.primer_apellido, 
        IF(usuario.segundo_apellido IS NOT NULL AND usuario.segundo_apellido <> '', CONCAT(' ', usuario.segundo_apellido), '')
    ) AS nombre_completo, 
    empresa.id_empresa, 
    empresa.razon_social AS empresa, 
    COUNT(reserva.id_reserva) AS total_reservas_usuario, 
    ROUND(subconsulta_promedio.promedio_reservas_empresa, 2) AS promedio_empresa 
FROM usuario 
INNER JOIN empresa ON usuario.id_empresa = empresa.id_empresa 
LEFT JOIN reserva ON usuario.id_usuario = reserva.id_usuario 
INNER JOIN (
    SELECT 
        usuario.id_empresa, 
        AVG(conteo_usuario.reservas_por_usuario) AS promedio_reservas_empresa 
    FROM usuario 
    INNER JOIN (
        SELECT 
            usuario.id_usuario, 
            usuario.id_empresa, 
            COUNT(reserva.id_reserva) AS reservas_por_usuario 
        FROM usuario 
        LEFT JOIN reserva ON usuario.id_usuario = reserva.id_usuario 
        WHERE usuario.id_empresa IS NOT NULL 
        GROUP BY 
            usuario.id_usuario, 
            usuario.id_empresa
    ) AS conteo_usuario ON usuario.id_usuario = conteo_usuario.id_usuario 
    GROUP BY usuario.id_empresa
) AS subconsulta_promedio ON empresa.id_empresa = subconsulta_promedio.id_empresa 
GROUP BY 
    usuario.id_usuario, 
    usuario.tipo_documento, 
    usuario.numero_documento, 
    usuario.primer_nombre, 
    usuario.segundo_nombre, 
    usuario.primer_apellido, 
    usuario.segundo_apellido, 
    empresa.id_empresa, 
    empresa.razon_social, 
    subconsulta_promedio.promedio_reservas_empresa 
HAVING COUNT(reserva.id_reserva) > subconsulta_promedio.promedio_reservas_empresa 
ORDER BY 
    total_reservas_usuario DESC, 
    empresa.razon_social ASC;
    
-- CONSULTA 97: Mostrar las 3 empresas con más empleados activos en el coworking. 
-- Hecho por Exneider Nava.

SELECT 
    empresa.id_empresa, 
    empresa.razon_social, 
    empresa.nit_ruc, 
    empresa.email, 
    COUNT(DISTINCT usuario.id_usuario) AS total_empleados_activos 
FROM empresa 
INNER JOIN usuario ON empresa.id_empresa = usuario.id_empresa 
INNER JOIN membresia ON usuario.id_usuario = membresia.id_usuario 
WHERE membresia.estado = 'activa' 
GROUP BY 
    empresa.id_empresa, 
    empresa.razon_social, 
    empresa.nit_ruc, 
    empresa.email 
ORDER BY 
    total_empleados_activos DESC, 
    empresa.razon_social ASC 
LIMIT 3;

-- CONSULTA 98: Calcular el porcentaje de usuarios activos frente al total de registrados. 
-- Hecho por Exneider Nava.

SELECT 
    (SELECT COUNT(*) FROM usuario) AS total_usuarios_registrados, 
    (
        SELECT COUNT(DISTINCT membresia.id_usuario) 
        FROM membresia 
        WHERE membresia.estado = 'activa'
    ) AS total_usuarios_activos, 
    ROUND(
        (
            (
                SELECT COUNT(DISTINCT membresia.id_usuario) 
                FROM membresia 
                WHERE membresia.estado = 'activa'
            ) * 100.0 / (SELECT COUNT(*) FROM usuario)
        ), 2
    ) AS porcentaje_usuarios_activos;

-- CONSULTA 99: Mostrar ingresos mensuales acumulados con función de ventana (OVER). 
-- Hecho por Exneider Nava.

SELECT 
    DATE_FORMAT(pago.fecha_pago, '%Y-%m') AS mes_anio, 
    COUNT(pago.id_pago) AS total_transacciones, 
    SUM(pago.monto) AS ingresos_mes, 
    SUM(SUM(pago.monto)) OVER (
        ORDER BY DATE_FORMAT(pago.fecha_pago, '%Y-%m') 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS ingresos_acumulados 
FROM pago 
WHERE pago.estado_pago = 'pagado' 
GROUP BY DATE_FORMAT(pago.fecha_pago, '%Y-%m') 
ORDER BY mes_anio ASC;

-- CONSULTA 100: Usuarios con más de 10 reservas, más de $500 en facturación y membresía activa. 
-- Hecho por Exneider Nava.

SELECT 
    usuario.id_usuario, 
    usuario.tipo_documento, 
    usuario.numero_documento, 
    CONCAT(
        usuario.primer_nombre, 
        IF(usuario.segundo_nombre IS NOT NULL AND usuario.segundo_nombre <> '', CONCAT(' ', usuario.segundo_nombre), ''), 
        ' ', 
        usuario.primer_apellido, 
        IF(usuario.segundo_apellido IS NOT NULL AND usuario.segundo_apellido <> '', CONCAT(' ', usuario.segundo_apellido), '')
    ) AS cliente_vip, 
    usuario.email, 
    usuario.telefono, 
    membresia.estado AS estado_membresia, 
    reserva_sub.total_reservas, 
    factura_sub.total_facturado 
FROM usuario 
INNER JOIN membresia ON usuario.id_usuario = membresia.id_usuario 
INNER JOIN (
    SELECT 
        reserva.id_usuario, 
        COUNT(reserva.id_reserva) AS total_reservas 
    FROM reserva 
    GROUP BY reserva.id_usuario 
    HAVING COUNT(reserva.id_reserva) > 10
) AS reserva_sub ON usuario.id_usuario = reserva_sub.id_usuario 
INNER JOIN (
    SELECT 
        factura.id_usuario, 
        SUM(factura.monto_total) AS total_facturado 
    FROM factura 
    WHERE factura.estado_factura <> 'anulada' 
    GROUP BY factura.id_usuario 
    HAVING SUM(factura.monto_total) > 500
) AS factura_sub ON usuario.id_usuario = factura_sub.id_usuario 
WHERE membresia.estado = 'activa' 
ORDER BY 
    factura_sub.total_facturado DESC, 
    reserva_sub.total_reservas DESC;