-- MÓDULO: Pagos y Facturación
-- Consulta 41. Listar todos los pagos realizados con método tarjeta.
-- Hecho por Yeimer Torres
use coworking_db;
SELECT
  p.id_pago,
  p.fecha_pago,
  p.monto,
  p.estado_pago,
  u.primer_nombre,
  u.primer_apellido,
  u.email
FROM pago as p
INNER JOIN usuario as u ON u.id_usuario = p.id_usuario
WHERE p.metodo_pago = 'tarjeta'
ORDER BY p.fecha_pago;

-- Consulta 42. Listar todas las facturas con estado pendiente junto al usuario al que pertenecen.
-- Hecho por Yeimer Torres
use coworking_db;
SELECT
  f.id_factura,
  f.fecha_emision,
  f.fecha_vencimiento,
  f.monto_total,
  f.saldo_pendiente,
  u.primer_nombre,
  u.primer_apellido,
  u.email
FROM factura as f
INNER JOIN usuario as u ON u.id_usuario = f.id_usuario
WHERE f.estado_factura = 'pendiente'
ORDER BY f.fecha_vencimiento;

-- Consulta 43. Calcular el total recaudado (pagos en estado pagado) agrupado por método de pago.
-- Hecho por Yeimer Torres
use coworking_db;
SELECT
  p.metodo_pago,
  COUNT(p.id_pago) AS cantidad_pagos,
  SUM(p.monto) AS total_recaudado
FROM pago as p
WHERE p.estado_pago = 'pagado'
GROUP BY p.metodo_pago
ORDER BY total_recaudado DESC;

-- Consulta 44. Listar las facturas anuladas con su motivo de anulación y el usuario afectado.
-- Hecho por Yeimer Torres
use coworking_db;
SELECT
  f.id_factura,
  f.fecha_emision,
  f.monto_total,
  f.motivo_anulacion,
  u.primer_nombre,
  u.primer_apellido,
  u.email
FROM factura as f
INNER JOIN usuario as u ON u.id_usuario = f.id_usuario
WHERE f.estado_factura = 'anulada'
ORDER BY f.fecha_emision;

-- Consulta 45. Calcular el saldo pendiente total de todas las facturas en estado pendiente.
-- Hecho por Yeimer Torres
use coworking_db;
SELECT
  COUNT(f.id_factura) AS facturas_pendientes,
  COALESCE(SUM(f.saldo_pendiente), 0) AS saldo_pendiente_total
FROM factura as f
WHERE f.estado_factura = 'pendiente';

-- Consulta 46. Listar las facturas vencidas que aún tienen saldo pendiente, con los días de retraso.
-- Hecho por Yeimer Torres
use coworking_db;
SELECT
  f.id_factura,
  f.fecha_vencimiento,
  DATEDIFF(CURDATE(), f.fecha_vencimiento) AS dias_vencida,
  f.saldo_pendiente,
  u.primer_nombre,
  u.primer_apellido,
  u.email
FROM factura as f
INNER JOIN usuario as u ON u.id_usuario = f.id_usuario
WHERE f.estado_factura = 'pendiente'
  AND f.saldo_pendiente > 0
  AND f.fecha_vencimiento < CURDATE()
ORDER BY dias_vencida DESC;

-- Consulta 47. Mostrar cada factura con el total pagado hasta el momento (solo pagos en estado pagado).
-- Hecho por Yeimer Torres
use coworking_db;
SELECT
  f.id_factura,
  f.estado_factura,
  f.monto_total,
  COALESCE(SUM(p.monto), 0) AS total_pagado
FROM factura as f
LEFT JOIN pago as p ON p.id_factura = f.id_factura AND p.estado_pago = 'pagado'
GROUP BY f.id_factura, f.estado_factura, f.monto_total
ORDER BY f.id_factura;

-- Consulta 48. Listar los usuarios que tienen más de una factura pendiente.
-- Hecho por Yeimer Torres
use coworking_db;
SELECT
  u.id_usuario,
  u.primer_nombre,
  u.primer_apellido,
  u.email,
  COUNT(f.id_factura) AS facturas_pendientes,
  SUM(f.saldo_pendiente) AS saldo_adeudado
FROM usuario as u
INNER JOIN factura as f ON f.id_usuario = u.id_usuario
WHERE f.estado_factura = 'pendiente'
GROUP BY u.id_usuario, u.primer_nombre, u.primer_apellido, u.email
HAVING COUNT(f.id_factura) > 1
ORDER BY facturas_pendientes DESC;

-- Consulta 49. Obtener el ingreso mensual (pagos en estado pagado) agrupado por año y mes.
-- Hecho por Yeimer Torres
use coworking_db;
SELECT
  YEAR(p.fecha_pago) AS anio,
  MONTH(p.fecha_pago) AS mes,
  COUNT(p.id_pago) AS cantidad_pagos,
  SUM(p.monto) AS ingreso_mensual
FROM pago as p
WHERE p.estado_pago = 'pagado'
GROUP BY YEAR(p.fecha_pago), MONTH(p.fecha_pago)
ORDER BY anio, mes;

-- Consulta 50. Listar las facturas emitidas a nombre de una empresa, mostrando su razón social y NIT.
-- Hecho por Yeimer Torres
use coworking_db;
SELECT
  f.id_factura,
  f.fecha_emision,
  f.monto_total,
  f.estado_factura,
  e.razon_social,
  e.nit_ruc
FROM factura as f
INNER JOIN empresa as e ON e.id_empresa = f.id_empresa
ORDER BY e.razon_social, f.fecha_emision;

-- Consulta 51. Mostrar el detalle de cada factura con su descripción y monto, junto al usuario facturado.
-- Hecho por Yeimer Torres
use coworking_db;
SELECT
  f.id_factura,
  d.id_detalle,
  d.descripcion,
  d.monto,
  d.id_membresia,
  d.id_reserva,
  d.id_usuario_servicio,
  u.primer_nombre,
  u.primer_apellido
FROM detalle_factura as d
INNER JOIN factura as f ON f.id_factura = d.id_factura
INNER JOIN usuario as u ON u.id_usuario = f.id_usuario
ORDER BY f.id_factura, d.id_detalle;

-- Consulta 52. Listar las facturas que tienen recargo mayor a cero.
-- Hecho por Yeimer Torres
use coworking_db;
SELECT
  f.id_factura,
  f.monto_total,
  f.recargo,
  (f.monto_total + f.recargo) AS total_con_recargo,
  f.estado_factura,
  u.primer_nombre,
  u.primer_apellido
FROM factura as f
INNER JOIN usuario as u ON u.id_usuario = f.id_usuario
WHERE f.recargo > 0
ORDER BY f.recargo DESC;

-- Consulta 53. Obtener el pago de mayor monto registrado, con los datos del usuario y la factura.
-- Hecho por Yeimer Torres
use coworking_db;
SELECT
  p.id_pago,
  p.id_factura,
  p.fecha_pago,
  p.monto,
  p.metodo_pago,
  p.estado_pago,
  u.primer_nombre,
  u.primer_apellido
FROM pago as p
INNER JOIN usuario as u ON u.id_usuario = p.id_usuario
WHERE p.monto = (SELECT MAX(monto) FROM pago);

-- Consulta 54. Calcular el monto promedio, mínimo y máximo de las facturas agrupadas por tipo de concepto.
-- Hecho por Yeimer Torres
use coworking_db;
SELECT
  f.tipo_concepto,
  COUNT(f.id_factura) AS cantidad_facturas,
  ROUND(AVG(f.monto_total), 2) AS monto_promedio,
  MIN(f.monto_total) AS monto_minimo,
  MAX(f.monto_total) AS monto_maximo
FROM factura as f
GROUP BY f.tipo_concepto
ORDER BY monto_promedio DESC;

-- Consulta 55. Listar las facturas que no tienen ningún pago registrado.
-- Hecho por Yeimer Torres
use coworking_db;
SELECT
  f.id_factura,
  f.fecha_emision,
  f.monto_total,
  f.estado_factura,
  u.primer_nombre,
  u.primer_apellido
FROM factura as f
INNER JOIN usuario as u ON u.id_usuario = f.id_usuario
LEFT JOIN pago as p ON p.id_factura = f.id_factura
WHERE p.id_pago IS NULL
ORDER BY f.fecha_emision;

-- Consulta 56. Contar la cantidad de pagos y el monto acumulado por cada estado de pago.
-- Hecho por Yeimer Torres
use coworking_db;
SELECT
  p.estado_pago,
  COUNT(p.id_pago) AS cantidad_pagos,
  SUM(p.monto) AS monto_acumulado
FROM pago as p
GROUP BY p.estado_pago
ORDER BY cantidad_pagos DESC;

-- Consulta 57. Mostrar por usuario el total facturado (sin anuladas) y el total pagado (solo pagos en estado pagado).
-- Hecho por Yeimer Torres
use coworking_db;
SELECT
  u.id_usuario,
  u.primer_nombre,
  u.primer_apellido,
  COALESCE(f.total_facturado, 0) AS total_facturado,
  COALESCE(p.total_pagado, 0) AS total_pagado
FROM usuario as u
LEFT JOIN (
  SELECT id_usuario, SUM(monto_total) AS total_facturado
  FROM factura
  WHERE estado_factura <> 'anulada'
  GROUP BY id_usuario
) as f ON f.id_usuario = u.id_usuario
LEFT JOIN (
  SELECT id_usuario, SUM(monto) AS total_pagado
  FROM pago
  WHERE estado_pago = 'pagado'
  GROUP BY id_usuario
) as p ON p.id_usuario = u.id_usuario
WHERE f.total_facturado IS NOT NULL OR p.total_pagado IS NOT NULL
ORDER BY total_facturado DESC;

-- Consulta 58. Listar los pagos cuyo monto es distinto al monto total de la factura que cancelan.
-- Hecho por Yeimer Torres
use coworking_db;
SELECT
  p.id_pago,
  p.id_factura,
  p.monto AS monto_pago,
  f.monto_total AS monto_factura,
  (f.monto_total - p.monto) AS diferencia,
  p.metodo_pago,
  p.estado_pago
FROM pago as p
INNER JOIN factura as f ON f.id_factura = p.id_factura
WHERE p.monto <> f.monto_total
ORDER BY p.id_pago;

-- Consulta 59. Calcular el total facturado (sin anuladas) por empresa, mostrando razón social y cantidad de facturas.
-- Hecho por Yeimer Torres
use coworking_db;
SELECT
  e.id_empresa,
  e.razon_social,
  e.nit_ruc,
  COUNT(f.id_factura) AS cantidad_facturas,
  SUM(f.monto_total) AS total_facturado
FROM empresa as e
INNER JOIN factura as f ON f.id_empresa = e.id_empresa
WHERE f.estado_factura <> 'anulada'
GROUP BY e.id_empresa, e.razon_social, e.nit_ruc
ORDER BY total_facturado DESC;

-- Consulta 60. Obtener el top 5 de usuarios que más dinero han pagado (solo pagos en estado pagado).
-- Hecho por Yeimer Torres
use coworking_db;
SELECT
  u.id_usuario,
  u.primer_nombre,
  u.primer_apellido,
  u.email,
  COUNT(p.id_pago) AS cantidad_pagos,
  SUM(p.monto) AS total_pagado
FROM usuario as u
INNER JOIN pago as p ON p.id_usuario = u.id_usuario
WHERE p.estado_pago = 'pagado'
GROUP BY u.id_usuario, u.primer_nombre, u.primer_apellido, u.email
ORDER BY total_pagado DESC
LIMIT 5;