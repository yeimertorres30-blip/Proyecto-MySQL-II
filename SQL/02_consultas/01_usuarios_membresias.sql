USE coworking_db;

-- CONSULTA 01
-- Listar todos los usuarios con su información básica.
-- hecho por carlos said.

SELECT 
    id_usuario,
    tipo_documento,
    numero_documento,
    CONCAT_WS(' ', primer_nombre, segundo_nombre, primer_apellido, segundo_apellido) AS nombre_completo,
    email,
    telefono,
    fecha_registro
FROM usuario;

-- CONSULTA 02
-- Listar los usuarios con membresía activa.
-- hecho por carlos said.

SELECT 
    u.id_usuario,
    CONCAT_WS(' ', u.primer_nombre, u.segundo_nombre, u.primer_apellido, u.segundo_apellido) AS nombre_completo,
    u.email,
    tm.nombre AS tipo_membresia,
    m.fecha_inicio,
    m.fecha_vencimiento,
    m.estado AS estado_membresia
FROM usuario u
INNER JOIN membresia m 
    ON u.id_usuario = m.id_usuario
INNER JOIN tipo_membresia tm 
    ON m.id_tipo_membresia = tm.id_tipo_membresia
WHERE m.estado = 'activa';

-- CONSULTA 03
-- Listar los usuarios cuya membresía está vencida.
-- hecho por carlos said.

SELECT 
    u.id_usuario,
    CONCAT_WS(' ', u.primer_nombre, u.segundo_nombre, u.primer_apellido, u.segundo_apellido) AS nombre_completo,
    u.email,
    tm.nombre AS tipo_membresia,
    m.fecha_inicio,
    m.fecha_vencimiento,
    m.estado AS estado_membresia
FROM usuario u
INNER JOIN membresia m 
    ON u.id_usuario = m.id_usuario
INNER JOIN tipo_membresia tm 
    ON m.id_tipo_membresia = tm.id_tipo_membresia
WHERE m.estado = 'vencida';

-- CONSULTA 04
-- Listar los usuarios con membresía suspendida.
-- hecho por carlos said.

SELECT 
    u.id_usuario,
    CONCAT_WS(' ', u.primer_nombre, u.segundo_nombre, u.primer_apellido, u.segundo_apellido) AS nombre_completo,
    u.email,
    tm.nombre AS tipo_membresia,
    m.fecha_inicio,
    m.fecha_vencimiento,
    m.estado AS estado_membresia
FROM usuario u
INNER JOIN membresia m 
    ON u.id_usuario = m.id_usuario
INNER JOIN tipo_membresia tm 
    ON m.id_tipo_membresia = tm.id_tipo_membresia
WHERE m.estado = 'suspendida';

-- CONSULTA 05
-- Contar cuántos usuarios tienen cada tipo de membresía.
-- hecho por carlos said.

SELECT 
    tm.id_tipo_membresia,
    tm.nombre AS tipo_membresia,
    COUNT(m.id_membresia) AS total_usuarios
FROM tipo_membresia tm
LEFT JOIN membresia m 
    ON tm.id_tipo_membresia = m.id_tipo_membresia
GROUP BY 
    tm.id_tipo_membresia, 
    tm.nombre
ORDER BY 
    total_usuarios DESC;

-- CONSULTA 06
-- Mostrar el top 10 de usuarios con más antigüedad en el coworking.
-- hecho por carlos said.

SELECT 
    id_usuario,
    CONCAT_WS(' ', primer_nombre, segundo_nombre, primer_apellido, segundo_apellido) AS nombre_completo,
    email,
    fecha_registro,
    DATEDIFF(CURRENT_DATE, fecha_registro) AS dias_antiguedad
FROM usuario
ORDER BY fecha_registro ASC
LIMIT 10;

-- CONSULTA 07
-- Listar usuarios que pertenecen a una empresa específica.
-- hecho por carlos said.

SELECT 
    e.id_empresa,
    e.razon_social AS empresa,
    u.id_usuario,
    CONCAT_WS(' ', u.primer_nombre, u.segundo_nombre, u.primer_apellido, u.segundo_apellido) AS nombre_completo,
    u.email,
    u.telefono,
    u.tipo_usuario
FROM usuario u
INNER JOIN empresa e 
    ON u.id_empresa = e.id_empresa
WHERE e.razon_social = 'TechInnovate S.A.S.';

-- CONSULTA 08
-- Contar cuántos usuarios están asociados a cada empresa. hecho por carlos said.
-- hecho por carlos said.

SELECT 
    e.id_empresa,
    e.razon_social AS empresa,
    e.nit_ruc,
    COUNT(u.id_usuario) AS total_usuarios
FROM empresa e
LEFT JOIN usuario u 
    ON e.id_empresa = u.id_empresa
GROUP BY 
    e.id_empresa, 
    e.razon_social,
    e.nit_ruc
ORDER BY 
    total_usuarios DESC;

-- CONSULTA 09
-- Mostrar usuarios que nunca han hecho una reserva. 
-- hecho por carlos said.

SELECT 
    u.id_usuario,
    CONCAT_WS(' ', u.primer_nombre, u.segundo_nombre, u.primer_apellido, u.segundo_apellido) AS nombre_completo,
    u.email,
    u.fecha_registro
FROM usuario u
LEFT JOIN reserva r 
    ON u.id_usuario = r.id_usuario
WHERE r.id_reserva IS NULL;

-- CONSULTA 10
-- Mostrar usuarios con más de 5 reservas activas en el mes. 
-- hecho por carlos said.

SELECT 
    u.id_usuario,
    CONCAT_WS(' ', u.primer_nombre, u.segundo_nombre, u.primer_apellido, u.segundo_apellido) AS nombre_completo,
    u.email,
    COUNT(r.id_reserva) AS total_reservas_mes
FROM usuario u
INNER JOIN reserva r 
    ON u.id_usuario = r.id_usuario
WHERE r.estado_reserva IN ('confirmada', 'pendiente', 'completada')
  AND MONTH(r.fecha_reserva) = MONTH(CURRENT_DATE)
  AND YEAR(r.fecha_reserva) = YEAR(CURRENT_DATE)
GROUP BY 
    u.id_usuario, 
    u.primer_nombre, 
    u.segundo_nombre, 
    u.primer_apellido, 
    u.segundo_apellido, 
    u.email
HAVING COUNT(r.id_reserva) > 5;

-- CONSULTA 11
-- Calcular el promedio de edad de los usuarios. 
-- hecho por carlos said.

SELECT 
    ROUND(AVG(TIMESTAMPDIFF(YEAR, fecha_nacimiento, CURRENT_DATE)), 1) AS promedio_edad
FROM usuario;

-- CONSULTA 12
-- Listar usuarios que han cambiado de membresía más de 2 veces. 
-- hecho por carlos said.

SELECT 
    u.id_usuario,
    CONCAT_WS(' ', u.primer_nombre, u.segundo_nombre, u.primer_apellido, u.segundo_apellido) AS nombre_completo,
    u.email,
    COUNT(m.id_membresia) AS total_membresias_registradas
FROM usuario u
INNER JOIN membresia m 
    ON u.id_usuario = m.id_usuario
GROUP BY 
    u.id_usuario,
    u.primer_nombre,
    u.segundo_nombre,
    u.primer_apellido,
    u.segundo_apellido,
    u.email
HAVING COUNT(m.id_membresia) > 2;

-- CONSULTA 13
-- Listar usuarios que han gastado más de $500 en reservas. 
-- hecho por carlos said.

SELECT 
    u.id_usuario,
    CONCAT_WS(' ', u.primer_nombre, u.segundo_nombre, u.primer_apellido, u.segundo_apellido) AS nombre_completo,
    u.email,
    SUM(df.monto) AS total_gastado_reservas
FROM usuario u
INNER JOIN factura f 
    ON u.id_usuario = f.id_usuario
INNER JOIN detalle_factura df 
    ON f.id_factura = df.id_factura
WHERE df.id_reserva IS NOT NULL
  AND f.estado_factura = 'pagada'
GROUP BY 
    u.id_usuario,
    u.primer_nombre,
    u.segundo_nombre,
    u.primer_apellido,
    u.segundo_apellido,
    u.email
HAVING SUM(df.monto) > 500;

-- CONSULTA 14
-- Mostrar usuarios que tienen tanto membresía como servicios adicionales. 
-- hecho por carlos said.

SELECT DISTINCT
    u.id_usuario,
    CONCAT_WS(' ', u.primer_nombre, u.segundo_nombre, u.primer_apellido, u.segundo_apellido) AS nombre_completo,
    u.email,
    m.estado AS estado_membresia
FROM usuario u
INNER JOIN membresia m 
    ON u.id_usuario = m.id_usuario
INNER JOIN usuario_servicio us 
    ON u.id_usuario = us.id_usuario;

-- CONSULTA 15
-- Listar usuarios con membresía Premium y reservas activas. 
-- hecho por carlos said.

SELECT DISTINCT
    u.id_usuario,
    CONCAT_WS(' ', u.primer_nombre, u.segundo_nombre, u.primer_apellido, u.segundo_apellido) AS nombre_completo,
    u.email,
    tm.nombre AS tipo_membresia,
    m.estado AS estado_membresia,
    r.estado_reserva
FROM usuario u
INNER JOIN membresia m 
    ON u.id_usuario = m.id_usuario
INNER JOIN tipo_membresia tm 
    ON m.id_tipo_membresia = tm.id_tipo_membresia
INNER JOIN reserva r 
    ON u.id_usuario = r.id_usuario
WHERE tm.nombre = 'Premium'
  AND m.estado = 'activa'
  AND r.estado_reserva IN ('confirmada', 'pendiente');

-- CONSULTA 16
-- Mostrar usuarios con membresía Corporativa y su empresa. 
-- hecho por carlos said.

SELECT DISTINCT
    u.id_usuario,
    CONCAT_WS(' ', u.primer_nombre, u.segundo_nombre, u.primer_apellido, u.segundo_apellido) AS nombre_completo,
    u.email,
    e.razon_social AS empresa,
    e.nit_ruc,
    tm.nombre AS tipo_membresia,
    m.estado AS estado_membresia
FROM usuario u
INNER JOIN empresa e 
    ON u.id_empresa = e.id_empresa
INNER JOIN membresia m 
    ON u.id_usuario = m.id_usuario
INNER JOIN tipo_membresia tm 
    ON m.id_tipo_membresia = tm.id_tipo_membresia
WHERE tm.nombre = 'Corporativa'
  AND m.estado = 'activa';

-- CONSULTA 17
-- Identificar usuarios con membresía diaria que la han renovado más de 10 veces.
-- hecho por carlos said.

SELECT 
    u.id_usuario,
    CONCAT_WS(' ', u.primer_nombre, u.segundo_nombre, u.primer_apellido, u.segundo_apellido) AS nombre_completo,
    u.email,
    tm.nombre AS tipo_membresia,
    COUNT(m.id_membresia) AS total_renovaciones
FROM usuario u
INNER JOIN membresia m 
    ON u.id_usuario = m.id_usuario
INNER JOIN tipo_membresia tm 
    ON m.id_tipo_membresia = tm.id_tipo_membresia
WHERE tm.nombre = 'Diaria'
GROUP BY 
    u.id_usuario,
    u.primer_nombre,
    u.segundo_nombre,
    u.primer_apellido,
    u.segundo_apellido,
    u.email,
    tm.nombre
HAVING COUNT(m.id_membresia) > 10;

-- CONSULTA 18
-- Mostrar usuarios cuya membresía vence en los próximos 7 días. 
-- hecho por carlos said.

SELECT 
    u.id_usuario,
    CONCAT_WS(' ', u.primer_nombre, u.segundo_nombre, u.primer_apellido, u.segundo_apellido) AS nombre_completo,
    u.email,
    tm.nombre AS tipo_membresia,
    m.fecha_inicio,
    m.fecha_vencimiento,
    DATEDIFF(m.fecha_vencimiento, CURRENT_DATE) AS dias_para_vencer
FROM usuario u
INNER JOIN membresia m 
    ON u.id_usuario = m.id_usuario
INNER JOIN tipo_membresia tm 
    ON m.id_tipo_membresia = tm.id_tipo_membresia
WHERE m.estado = 'activa'
  AND m.fecha_vencimiento BETWEEN CURRENT_DATE AND DATE_ADD(CURRENT_DATE, INTERVAL 7 DAY)
ORDER BY m.fecha_vencimiento ASC;

-- CONSULTA 19
-- Listar usuarios que se registraron en el último mes.
-- hecho por carlos said.
SELECT 
    id_usuario,
    CONCAT_WS(' ', primer_nombre, segundo_nombre, primer_apellido, segundo_apellido) AS nombre_completo,
    email,
    telefono,
    tipo_usuario,
    fecha_registro
FROM usuario
WHERE fecha_registro >= DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH)
ORDER BY fecha_registro DESC;

-- CONSULTA 20
-- Mostrar usuarios que nunca han asistido al coworking (0 accesos).
-- hecho por carlos said.

SELECT 
    u.id_usuario,
    CONCAT_WS(' ', u.primer_nombre, u.segundo_nombre, u.primer_apellido, u.segundo_apellido) AS nombre_completo,
    u.email,
    u.telefono,
    u.fecha_registro
FROM usuario u
LEFT JOIN control_acceso ca 
    ON u.id_usuario = ca.id_usuario
WHERE ca.id_acceso IS NULL;