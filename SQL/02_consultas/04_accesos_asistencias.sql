-- 61. Listar todos los accesos registrados hoy
SELECT 
    ca.id_acceso,
    ca.id_usuario,
    CONCAT(u.primer_nombre, ' ', COALESCE(u.segundo_nombre, ''), ' ', u.primer_apellido) AS nombre_usuario,
    ca.fecha_hora_entrada,
    ca.fecha_hora_salida,
    ca.metodo_acceso,
    ca.codigo_leido,
    ca.estado_acceso,
    ca.motivo_rechazo
FROM control_acceso ca
LEFT JOIN usuario u ON ca.id_usuario = u.id_usuario
WHERE DATE(ca.fecha_hora_entrada) = CURRENT_DATE
ORDER BY ca.fecha_hora_entrada;

-- 62. Mostrar usuarios con más de 20 asistencias en el mes actual
SELECT 
    u.id_usuario,
    CONCAT(u.primer_nombre, ' ', u.primer_apellido) AS nombre,
    COUNT(*) AS total_asistencias
FROM control_acceso ca
INNER JOIN usuario u ON ca.id_usuario = u.id_usuario
WHERE ca.estado_acceso = 'permitido'
  AND YEAR(ca.fecha_hora_entrada) = YEAR(CURRENT_DATE)
  AND MONTH(ca.fecha_hora_entrada) = MONTH(CURRENT_DATE)
GROUP BY u.id_usuario, u.primer_nombre, u.primer_apellido
HAVING COUNT(*) > 20
ORDER BY total_asistencias DESC;

-- 63. Mostrar usuarios que no asistieron en la última semana
SELECT 
    u.id_usuario,
    CONCAT(u.primer_nombre, ' ', u.primer_apellido) AS nombre,
    u.email,
    u.tipo_usuario
FROM usuario u
WHERE u.id_usuario NOT IN (
    SELECT DISTINCT ca.id_usuario
    FROM control_acceso ca
    WHERE ca.id_usuario IS NOT NULL
      AND ca.estado_acceso = 'permitido'
      AND ca.fecha_hora_entrada >= DATE_SUB(CURRENT_DATE, INTERVAL 7 DAY)
)
ORDER BY u.primer_apellido, u.primer_nombre;

-- 64. Calcular la asistencia promedio por día de la semana
SELECT 
    DAYOFWEEK(fecha) AS num_dia,
    DAYNAME(fecha) AS dia_semana,
    ROUND(AVG(conteo), 2) AS promedio_asistencias
FROM (
    SELECT 
        DATE(fecha_hora_entrada) AS fecha,
        COUNT(*) AS conteo
    FROM control_acceso
    WHERE estado_acceso = 'permitido'
    GROUP BY DATE(fecha_hora_entrada)
) AS diarios
GROUP BY num_dia, dia_semana
ORDER BY num_dia;

-- 65. Mostrar los 10 usuarios más constantes (más asistencias)
SELECT 
    u.id_usuario,
    CONCAT(u.primer_nombre, ' ', u.primer_apellido) AS nombre,
    COUNT(*) AS total_asistencias
FROM control_acceso ca
INNER JOIN usuario u ON ca.id_usuario = u.id_usuario
WHERE ca.estado_acceso = 'permitido'
GROUP BY u.id_usuario, u.primer_nombre, u.primer_apellido
ORDER BY total_asistencias DESC
LIMIT 10;

-- 66. Mostrar accesos fuera del horario permitido (asumiendo 07:00-21:00 según horarios de la BD)
SELECT 
    ca.id_acceso,
    ca.id_usuario,
    CONCAT(u.primer_nombre, ' ', u.primer_apellido) AS nombre,
    ca.fecha_hora_entrada,
    TIME(ca.fecha_hora_entrada) AS hora_entrada,
    ca.metodo_acceso,
    ca.estado_acceso
FROM control_acceso ca
LEFT JOIN usuario u ON ca.id_usuario = u.id_usuario
WHERE TIME(ca.fecha_hora_entrada) < '07:00:00'
   OR TIME(ca.fecha_hora_entrada) > '21:00:00'
ORDER BY ca.fecha_hora_entrada;

-- 67. Mostrar usuarios que accedieron sin membresía activa (rechazados)
SELECT DISTINCT
    u.id_usuario,
    CONCAT(u.primer_nombre, ' ', u.primer_apellido) AS nombre,
    u.email,
    ca.fecha_hora_entrada,
    ca.motivo_rechazo
FROM control_acceso ca
INNER JOIN usuario u ON ca.id_usuario = u.id_usuario
WHERE ca.estado_acceso = 'rechazado'
  AND (ca.motivo_rechazo LIKE '%Membresía no activa%' 
       OR ca.motivo_rechazo LIKE '%código QR expirado%')
ORDER BY ca.fecha_hora_entrada DESC;

-- 68. Listar usuarios que solo acceden los fines de semana
SELECT 
    u.id_usuario,
    CONCAT(u.primer_nombre, ' ', u.primer_apellido) AS nombre,
    COUNT(*) AS total_accesos_fin_semana
FROM control_acceso ca
INNER JOIN usuario u ON ca.id_usuario = u.id_usuario
WHERE ca.estado_acceso = 'permitido'
  AND DAYOFWEEK(ca.fecha_hora_entrada) IN (1, 7)  -- 1=Domingo, 7=Sábado
GROUP BY u.id_usuario, u.primer_nombre, u.primer_apellido
HAVING COUNT(*) = (
    SELECT COUNT(*)
    FROM control_acceso ca2
    WHERE ca2.id_usuario = u.id_usuario
      AND ca2.estado_acceso = 'permitido'
)
ORDER BY total_accesos_fin_semana DESC;

-- 69. Mostrar usuarios que accedieron más de 2 veces en el mismo día
SELECT 
    u.id_usuario,
    CONCAT(u.primer_nombre, ' ', u.primer_apellido) AS nombre,
    DATE(ca.fecha_hora_entrada) AS fecha,
    COUNT(*) AS accesos_en_el_dia
FROM control_acceso ca
INNER JOIN usuario u ON ca.id_usuario = u.id_usuario
WHERE ca.estado_acceso = 'permitido'
GROUP BY u.id_usuario, u.primer_nombre, u.primer_apellido, DATE(ca.fecha_hora_entrada)
HAVING COUNT(*) > 2
ORDER BY fecha DESC, accesos_en_el_dia DESC;

-- 70. Mostrar el total de accesos diarios en el último mes
SELECT 
    DATE(fecha_hora_entrada) AS fecha,
    COUNT(*) AS total_accesos,
    SUM(CASE WHEN estado_acceso = 'permitido' THEN 1 ELSE 0 END) AS permitidos,
    SUM(CASE WHEN estado_acceso = 'rechazado' THEN 1 ELSE 0 END) AS rechazados
FROM control_acceso
WHERE fecha_hora_entrada >= DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH)
GROUP BY DATE(fecha_hora_entrada)
ORDER BY fecha DESC;

-- 71. Mostrar usuarios que han accedido pero no tienen reservas
SELECT DISTINCT
    u.id_usuario,
    CONCAT(u.primer_nombre, ' ', u.primer_apellido) AS nombre,
    u.email,
    COUNT(ca.id_acceso) AS total_accesos
FROM control_acceso ca
INNER JOIN usuario u ON ca.id_usuario = u.id_usuario
WHERE ca.estado_acceso = 'permitido'
  AND u.id_usuario NOT IN (SELECT DISTINCT id_usuario FROM reserva WHERE id_usuario IS NOT NULL)
GROUP BY u.id_usuario, u.primer_nombre, u.primer_apellido, u.email
ORDER BY total_accesos DESC;

-- 72. Mostrar los días con más concurrencia en el coworking
SELECT 
    DATE(fecha_hora_entrada) AS fecha,
    DAYNAME(fecha_hora_entrada) AS dia_semana,
    COUNT(*) AS total_accesos
FROM control_acceso
WHERE estado_acceso = 'permitido'
GROUP BY DATE(fecha_hora_entrada), DAYNAME(fecha_hora_entrada)
ORDER BY total_accesos DESC
LIMIT 15;

-- 73. Mostrar usuarios que entraron pero no registraron salida
SELECT 
    ca.id_acceso,
    u.id_usuario,
    CONCAT(u.primer_nombre, ' ', u.primer_apellido) AS nombre,
    ca.fecha_hora_entrada,
    ca.metodo_acceso,
    ca.codigo_leido
FROM control_acceso ca
INNER JOIN usuario u ON ca.id_usuario = u.id_usuario
WHERE ca.fecha_hora_salida IS NULL
  AND ca.estado_acceso = 'permitido'
ORDER BY ca.fecha_hora_entrada DESC;

-- 74. Mostrar accesos de usuarios con membresía vencida
SELECT 
    ca.id_acceso,
    u.id_usuario,
    CONCAT(u.primer_nombre, ' ', u.primer_apellido) AS nombre,
    ca.fecha_hora_entrada,
    ca.estado_acceso,
    m.estado AS estado_membresia,
    m.fecha_vencimiento
FROM control_acceso ca
INNER JOIN usuario u ON ca.id_usuario = u.id_usuario
INNER JOIN membresia m ON u.id_usuario = m.id_usuario
WHERE m.estado = 'vencida'
  AND ca.fecha_hora_entrada BETWEEN m.fecha_inicio AND m.fecha_vencimiento + INTERVAL 30 DAY  -- margen de tolerancia
ORDER BY ca.fecha_hora_entrada DESC;

-- 75. Mostrar accesos de usuarios corporativos (empleados) por empresa
SELECT 
    e.razon_social AS empresa,
    u.id_usuario,
    CONCAT(u.primer_nombre, ' ', u.primer_apellido) AS nombre,
    COUNT(ca.id_acceso) AS total_accesos,
    SUM(CASE WHEN ca.estado_acceso = 'permitido' THEN 1 ELSE 0 END) AS permitidos
FROM control_acceso ca
INNER JOIN usuario u ON ca.id_usuario = u.id_usuario
INNER JOIN empresa e ON u.id_empresa = e.id_empresa
WHERE u.tipo_usuario = 'empleado'
GROUP BY e.id_empresa, e.razon_social, u.id_usuario, u.primer_nombre, u.primer_apellido
ORDER BY e.razon_social, total_accesos DESC;

-- 76. Mostrar clientes que nunca han usado el coworking a pesar de pagar membresía
SELECT DISTINCT
    u.id_usuario,
    CONCAT(u.primer_nombre, ' ', u.primer_apellido) AS nombre,
    u.email,
    m.fecha_inicio,
    m.fecha_vencimiento,
    m.estado AS estado_membresia,
    tm.nombre AS tipo_membresia
FROM usuario u
INNER JOIN membresia m ON u.id_usuario = m.id_usuario
INNER JOIN tipo_membresia tm ON m.id_tipo_membresia = tm.id_tipo_membresia
WHERE u.id_usuario NOT IN (
    SELECT DISTINCT id_usuario 
    FROM control_acceso 
    WHERE id_usuario IS NOT NULL AND estado_acceso = 'permitido'
)
ORDER BY m.fecha_inicio DESC;

-- 77. Mostrar accesos rechazados por intentos con QR inválido / expirado
SELECT 
    ca.id_acceso,
    ca.id_usuario,
    CONCAT(u.primer_nombre, ' ', u.primer_apellido) AS nombre,
    ca.fecha_hora_entrada,
    ca.metodo_acceso,
    ca.codigo_leido,
    ca.motivo_rechazo
FROM control_acceso ca
LEFT JOIN usuario u ON ca.id_usuario = u.id_usuario
WHERE ca.estado_acceso = 'rechazado'
  AND (ca.motivo_rechazo LIKE '%QR%' 
       OR ca.motivo_rechazo LIKE '%código QR%'
       OR ca.metodo_acceso = 'QR')
ORDER BY ca.fecha_hora_entrada DESC;

-- 78. Mostrar accesos promedio por usuario
SELECT 
    ROUND(AVG(total_accesos), 2) AS promedio_accesos_por_usuario
FROM (
    SELECT id_usuario, COUNT(*) AS total_accesos
    FROM control_acceso
    WHERE estado_acceso = 'permitido' AND id_usuario IS NOT NULL
    GROUP BY id_usuario
) AS por_usuario;

-- Versión detallada (promedio + ranking):
SELECT 
    u.id_usuario,
    CONCAT(u.primer_nombre, ' ', u.primer_apellido) AS nombre,
    COUNT(ca.id_acceso) AS total_accesos,
    ROUND(COUNT(ca.id_acceso) / (SELECT COUNT(DISTINCT DATE(fecha_hora_entrada)) FROM control_acceso WHERE estado_acceso = 'permitido'), 2) AS promedio_diario_aprox
FROM control_acceso ca
INNER JOIN usuario u ON ca.id_usuario = u.id_usuario
WHERE ca.estado_acceso = 'permitido'
GROUP BY u.id_usuario, u.primer_nombre, u.primer_apellido
ORDER BY total_accesos DESC;

-- 79. Identificar usuarios que asisten más en la mañana (antes de las 12:00)
SELECT 
    u.id_usuario,
    CONCAT(u.primer_nombre, ' ', u.primer_apellido) AS nombre,
    COUNT(*) AS accesos_manana,
    ROUND(COUNT(*) * 100.0 / (
        SELECT COUNT(*) FROM control_acceso ca2 
        WHERE ca2.id_usuario = u.id_usuario AND ca2.estado_acceso = 'permitido'
    ), 1) AS porcentaje_manana
FROM control_acceso ca
INNER JOIN usuario u ON ca.id_usuario = u.id_usuario
WHERE ca.estado_acceso = 'permitido'
  AND HOUR(ca.fecha_hora_entrada) < 12
GROUP BY u.id_usuario, u.primer_nombre, u.primer_apellido
HAVING COUNT(*) >= 3   -- mínimo para considerar "más"
ORDER BY accesos_manana DESC, porcentaje_manana DESC
LIMIT 20;

-- 80. Identificar usuarios que asisten más en la noche (a partir de las 18:00)
SELECT 
    u.id_usuario,
    CONCAT(u.primer_nombre, ' ', u.primer_apellido) AS nombre,
    COUNT(*) AS accesos_noche,
    ROUND(COUNT(*) * 100.0 / (
        SELECT COUNT(*) FROM control_acceso ca2 
        WHERE ca2.id_usuario = u.id_usuario AND ca2.estado_acceso = 'permitido'
    ), 1) AS porcentaje_noche
FROM control_acceso ca
INNER JOIN usuario u ON ca.id_usuario = u.id_usuario
WHERE ca.estado_acceso = 'permitido'
  AND HOUR(ca.fecha_hora_entrada) >= 18
GROUP BY u.id_usuario, u.primer_nombre, u.primer_apellido
HAVING COUNT(*) >= 2
ORDER BY accesos_noche DESC, porcentaje_noche DESC
LIMIT 20;