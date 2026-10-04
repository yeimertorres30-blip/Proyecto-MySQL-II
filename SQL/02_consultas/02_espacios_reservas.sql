use coworking_db;

-- ESPACIOS Y RESERVAS (hamilton quiroga)

-- 21. Listar todos los espacios disponibles con su capacidad.
SELECT 
    codigo_espacio,
    capacidad_maxima
FROM espacio
WHERE estado_disponibilidad = 'disponible';


-- 22. Listar reservas activas en el día actual.
SELECT 
    r.id_reserva,
    r.fecha_reserva,
    r.hora_inicio,
    r.hora_fin,
    r.estado_reserva,
    u.primer_nombre,
    u.primer_apellido,
    e.codigo_espacio
FROM reserva r
INNER JOIN usuario u ON r.id_usuario = u.id_usuario
INNER JOIN espacio e ON r.id_espacio = e.id_espacio
WHERE r.fecha_reserva = CURDATE()
AND r.estado_reserva IN ('pendiente', 'confirmada');


-- 23. Mostrar reservas canceladas en el último mes.
SELECT 
    r.id_reserva,
    r.fecha_reserva,
    r.hora_inicio,
    r.hora_fin,
    u.primer_nombre,
    u.primer_apellido,
    e.codigo_espacio
FROM reserva r
INNER JOIN usuario u ON r.id_usuario = u.id_usuario
INNER JOIN espacio e ON r.id_espacio = e.id_espacio
WHERE r.estado_reserva = 'cancelada'
AND r.fecha_reserva >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH);

-- 24. Listar reservas de salas de reuniones en horario pico
--     (9 am - 11 am).
SELECT 
    r.id_reserva,
    r.fecha_reserva,
    r.hora_inicio,
    r.hora_fin,
    e.codigo_espacio,
    u.primer_nombre,
    u.primer_apellido
FROM reserva r
INNER JOIN espacio e ON r.id_espacio = e.id_espacio
INNER JOIN tipo_espacio te ON e.id_tipo_espacio = te.id_tipo_espacio
INNER JOIN usuario u ON r.id_usuario = u.id_usuario
WHERE te.nombre = 'Sala de Reuniones'
AND r.hora_inicio >= '09:00:00'
AND r.hora_inicio < '11:00:00';

-- 25. Contar cuántas reservas se hacen por cada tipo de espacio.
SELECT 
    te.nombre AS tipo_espacio,
    COUNT(r.id_reserva) AS total_reservas
FROM tipo_espacio te
INNER JOIN espacio e ON te.id_tipo_espacio = e.id_tipo_espacio
LEFT JOIN reserva r ON e.id_espacio = r.id_espacio
GROUP BY te.id_tipo_espacio, te.nombre;

-- 26. Mostrar el espacio más reservado del último mes.
SELECT 
    e.codigo_espacio,
    te.nombre AS tipo_espacio,
    COUNT(r.id_reserva) AS total_reservas
FROM espacio e
INNER JOIN tipo_espacio te ON e.id_tipo_espacio = te.id_tipo_espacio
INNER JOIN reserva r ON e.id_espacio = r.id_espacio
WHERE r.fecha_reserva >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
GROUP BY e.id_espacio, e.codigo_espacio, te.nombre
ORDER BY total_reservas DESC
LIMIT 1;


-- 27. Listar usuarios que más han reservado salas privadas.
SELECT 
    u.id_usuario,
    u.primer_nombre,
    u.primer_apellido,
    COUNT(r.id_reserva) AS total_reservas
FROM usuario u
INNER JOIN reserva r ON u.id_usuario = r.id_usuario
INNER JOIN espacio e ON r.id_espacio = e.id_espacio
INNER JOIN tipo_espacio te ON e.id_tipo_espacio = te.id_tipo_espacio
WHERE te.nombre = 'Oficina Privada'
GROUP BY u.id_usuario, u.primer_nombre, u.primer_apellido
ORDER BY total_reservas DESC;


-- 28. Mostrar reservas que exceden la capacidad máxima del espacio.
SELECT 
    r.id_reserva,
    e.codigo_espacio,
    e.capacidad_maxima,
    r.numero_asistentes,
    r.fecha_reserva
FROM reserva r
INNER JOIN espacio e ON r.id_espacio = e.id_espacio
WHERE r.numero_asistentes > e.capacidad_maxima;


-- 29. Listar espacios que no se han reservado en la última semana.
SELECT 
    e.id_espacio,
    e.codigo_espacio,
    te.nombre AS tipo_espacio
FROM espacio e
INNER JOIN tipo_espacio te ON e.id_tipo_espacio = te.id_tipo_espacio
LEFT JOIN reserva r 
    ON e.id_espacio = r.id_espacio
    AND r.fecha_reserva >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
WHERE r.id_reserva IS NULL;


-- 30. Calcular la tasa de ocupación promedio de cada espacio.
SELECT 
    e.codigo_espacio,
    ROUND(
        SUM(TIME_TO_SEC(TIMEDIFF(r.hora_fin, r.hora_inicio))) /
        NULLIF(
            SUM(TIME_TO_SEC(TIMEDIFF(h.hora_cierre, h.hora_apertura))),
            0
        ) * 100,
        2
    ) AS tasa_ocupacion_porcentaje
FROM espacio e
INNER JOIN horario_espacio h ON e.id_espacio = h.id_espacio
LEFT JOIN reserva r 
    ON e.id_espacio = r.id_espacio
    AND r.estado_reserva IN ('confirmada', 'completada')
GROUP BY e.id_espacio, e.codigo_espacio;

-- 31. Mostrar reservas de más de 8 horas.
SELECT 
    r.id_reserva,
    r.fecha_reserva,
    r.hora_inicio,
    r.hora_fin,
    e.codigo_espacio,
    TIMESTAMPDIFF(
        MINUTE,
        r.hora_inicio,
        r.hora_fin
    ) / 60 AS horas_reserva
FROM reserva r
INNER JOIN espacio e ON r.id_espacio = e.id_espacio
WHERE TIMESTAMPDIFF(
    MINUTE,
    r.hora_inicio,
    r.hora_fin
) > 480;


-- 32. Identificar usuarios con más de 20 reservas en total.
SELECT 
    u.id_usuario,
    u.primer_nombre,
    u.primer_apellido,
    COUNT(r.id_reserva) AS total_reservas
FROM usuario u
INNER JOIN reserva r ON u.id_usuario = r.id_usuario
GROUP BY u.id_usuario, u.primer_nombre, u.primer_apellido
HAVING COUNT(r.id_reserva) > 20;


-- 33. Mostrar reservas realizadas por empresas con más de 10 empleados.
SELECT 
    r.id_reserva,
    r.fecha_reserva,
    r.hora_inicio,
    r.hora_fin,
    u.primer_nombre,
    u.primer_apellido,
    e.razon_social,
    e.id_empresa
FROM reserva r
INNER JOIN usuario u ON r.id_usuario = u.id_usuario
INNER JOIN empresa e ON u.id_empresa = e.id_empresa
WHERE e.id_empresa IN (
    SELECT id_empresa
    FROM usuario
    WHERE id_empresa IS NOT NULL
    GROUP BY id_empresa
    HAVING COUNT(*) > 10
);

-- 34. Listar reservas que se solapan en horario.
SELECT 
    r1.id_reserva AS reserva_1,
    r2.id_reserva AS reserva_2,
    r1.id_espacio,
    r1.fecha_reserva,
    r1.hora_inicio AS inicio_1,
    r1.hora_fin AS fin_1,
    r2.hora_inicio AS inicio_2,
    r2.hora_fin AS fin_2
FROM reserva r1
INNER JOIN reserva r2
    ON r1.id_espacio = r2.id_espacio
    AND r1.fecha_reserva = r2.fecha_reserva
    AND r1.id_reserva < r2.id_reserva
WHERE r1.hora_inicio < r2.hora_fin
AND r1.hora_fin > r2.hora_inicio
AND r1.estado_reserva <> 'cancelada'
AND r2.estado_reserva <> 'cancelada';

-- 35. Listar reservas de fin de semana.
SELECT 
    r.id_reserva,
    r.fecha_reserva,
    r.hora_inicio,
    r.hora_fin,
    u.primer_nombre,
    u.primer_apellido,
    e.codigo_espacio
FROM reserva r
INNER JOIN usuario u ON r.id_usuario = u.id_usuario
INNER JOIN espacio e ON r.id_espacio = e.id_espacio
WHERE DAYOFWEEK(r.fecha_reserva) IN (1, 7);


-- 36. Mostrar el porcentaje de ocupación por cada tipo de espacio.
SELECT 
    te.nombre AS tipo_espacio,
    ROUND(
        COUNT(r.id_reserva) * 100.0 /
        NULLIF(COUNT(e.id_espacio), 0),
        2
    ) AS porcentaje_ocupacion
FROM tipo_espacio te
INNER JOIN espacio e 
    ON te.id_tipo_espacio = e.id_tipo_espacio
LEFT JOIN reserva r 
    ON e.id_espacio = r.id_espacio
    AND r.estado_reserva IN ('confirmada', 'completada')
GROUP BY te.id_tipo_espacio, te.nombre;


-- 37. Mostrar la duración promedio de reservas por tipo de espacio.
SELECT 
    te.nombre AS tipo_espacio,
    ROUND(
        AVG(
            TIMESTAMPDIFF(
                MINUTE,
                r.hora_inicio,
                r.hora_fin
            ) / 60
        ),
        2
    ) AS promedio_horas
FROM tipo_espacio te
INNER JOIN espacio e 
    ON te.id_tipo_espacio = e.id_tipo_espacio
INNER JOIN reserva r 
    ON e.id_espacio = r.id_espacio
GROUP BY te.id_tipo_espacio, te.nombre;


-- 38. Mostrar reservas con servicios adicionales incluidos.
SELECT 
    r.id_reserva,
    r.fecha_reserva,
    e.codigo_espacio,
    sa.nombre AS servicio,
    rs.cantidad,
    rs.precio_aplicado,
    rs.sub_total
FROM reserva r
INNER JOIN espacio e 
    ON r.id_espacio = e.id_espacio
INNER JOIN reserva_servicio rs 
    ON r.id_reserva = rs.id_reserva
INNER JOIN servicio_adicional sa 
    ON rs.id_servicio = sa.id_servicio
ORDER BY r.id_reserva;


-- 39. Listar usuarios que reservaron sala de eventos
--     en los últimos 6 meses.
SELECT DISTINCT
    u.id_usuario,
    u.primer_nombre,
    u.primer_apellido,
    u.email,
    r.fecha_reserva
FROM usuario u
INNER JOIN reserva r 
    ON u.id_usuario = r.id_usuario
INNER JOIN espacio e 
    ON r.id_espacio = e.id_espacio
INNER JOIN tipo_espacio te 
    ON e.id_tipo_espacio = te.id_tipo_espacio
WHERE te.nombre = 'Sala de Eventos'
AND r.fecha_reserva >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH);


-- 40. Identificar reservas realizadas y nunca asistidas.
SELECT 
    r.id_reserva,
    r.fecha_reserva,
    r.hora_inicio,
    r.hora_fin,
    u.primer_nombre,
    u.primer_apellido,
    e.codigo_espacio
FROM reserva r
INNER JOIN usuario u 
    ON r.id_usuario = u.id_usuario
INNER JOIN espacio e 
    ON r.id_espacio = e.id_espacio
LEFT JOIN control_acceso ca 
    ON r.id_reserva = ca.id_reserva
    AND ca.estado_acceso = 'permitido'
WHERE r.estado_reserva IN ('confirmada', 'completada')
AND ca.id_acceso IS NULL;