/*
PROYECTO: Gestión de Coworking y Oficinas Compartidas
GRUPO: 03 Exneider, Said, Alvaro, Hamilton, Yeimer
MÓDULO: DDL - Estructura de Base de Datos y Creación de Tablas
ARCHIVO: 01_estructura.sql
DESCRIPCIÓN: Script de creación física de la base de datos `coworking_db`
REQUISITOS PREVIOS: Ejecución en cliente MySQL 8.0+.
*/
CREATE DATABASE IF NOT EXISTS coworking_db
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE coworking_db;

-- Deshabilitar la verificación de claves foráneas para permitir un reinicio/limpieza seguro
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS control_acceso;
DROP TABLE IF EXISTS detalle_factura;
DROP TABLE IF EXISTS pago;
DROP TABLE IF EXISTS factura;
DROP TABLE IF EXISTS log_auditoria;
DROP TABLE IF EXISTS reembolso_penalizacion;
DROP TABLE IF EXISTS reserva_servicio;
DROP TABLE IF EXISTS usuario_servicio;
DROP TABLE IF EXISTS servicio_adicional;
DROP TABLE IF EXISTS horario_espacio;
DROP TABLE IF EXISTS reserva;
DROP TABLE IF EXISTS espacio;
DROP TABLE IF EXISTS tipo_espacio;
DROP TABLE IF EXISTS membresia;
DROP TABLE IF EXISTS tipo_membresia;
DROP TABLE IF EXISTS usuario;
DROP TABLE IF EXISTS empresa;

SET FOREIGN_KEY_CHECKS = 1;

-- Tabla 1: empresa
CREATE TABLE IF NOT EXISTS empresa (
    id_empresa INT AUTO_INCREMENT PRIMARY KEY,
    razon_social VARCHAR(150) NOT NULL,
    nit_ruc VARCHAR(30) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla 2: usuario
CREATE TABLE IF NOT EXISTS usuario (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    tipo_documento ENUM('CC', 'CE', 'PPT', 'TI') NOT NULL,
    tipo_usuario ENUM('empleado', 'comun') NOT NULL DEFAULT 'comun',
    numero_documento VARCHAR(20) NOT NULL UNIQUE,
    primer_nombre VARCHAR(50) NOT NULL,
    segundo_nombre VARCHAR(50) NULL,
    primer_apellido VARCHAR(50) NOT NULL,
    segundo_apellido VARCHAR(50) NULL,
    fecha_nacimiento DATE NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    telefono VARCHAR(20) NULL,
    fecha_registro DATE NOT NULL DEFAULT (CURRENT_DATE),
    id_empresa INT NULL,
    codigo_qr VARCHAR(255) NULL UNIQUE,
    uid_rfid VARCHAR(100) NULL UNIQUE,
    ultima_fecha_acceso DATETIME NULL,
    CONSTRAINT fk_usuario_empresa FOREIGN KEY (id_empresa)
        REFERENCES empresa(id_empresa)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla 3: tipo_membresia
CREATE TABLE IF NOT EXISTS tipo_membresia (
    id_tipo_membresia INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    precio_base DECIMAL(10,2) NOT NULL,
    duracion_dias INT NOT NULL,
    descripcion VARCHAR(255) NULL,
    CONSTRAINT chk_tipo_membresia_precio CHECK (precio_base >= 0),
    CONSTRAINT chk_tipo_membresia_duracion CHECK (duracion_dias > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla 4: membresia
CREATE TABLE IF NOT EXISTS membresia (
    id_membresia INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    id_tipo_membresia INT NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    estado ENUM('activa', 'suspendida', 'vencida') NOT NULL DEFAULT 'activa',
    precio_cobrado DECIMAL(10,2) NOT NULL,
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_membresia_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_membresia_tipo FOREIGN KEY (id_tipo_membresia)
        REFERENCES tipo_membresia(id_tipo_membresia)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_membresia_fechas CHECK (fecha_vencimiento >= fecha_inicio),
    CONSTRAINT chk_membresia_precio CHECK (precio_cobrado >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla 5: tipo_espacio
CREATE TABLE IF NOT EXISTS tipo_espacio (
    id_tipo_espacio INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(255) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla 6: espacio
CREATE TABLE IF NOT EXISTS espacio (
    id_espacio INT AUTO_INCREMENT PRIMARY KEY,
    id_tipo_espacio INT NOT NULL,
    codigo_espacio VARCHAR(20) NOT NULL UNIQUE,
    capacidad_maxima INT NOT NULL,
    precio_por_hora DECIMAL(10,2) NOT NULL,
    estado_disponibilidad ENUM('disponible', 'mantenimiento', 'ocupado') NOT NULL DEFAULT 'disponible',
    CONSTRAINT fk_espacio_tipo FOREIGN KEY (id_tipo_espacio)
        REFERENCES tipo_espacio(id_tipo_espacio)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_espacio_capacidad CHECK (capacidad_maxima > 0),
    CONSTRAINT chk_espacio_precio CHECK (precio_por_hora >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla 7: horario_espacio
CREATE TABLE IF NOT EXISTS horario_espacio (
    id_horario INT AUTO_INCREMENT PRIMARY KEY,
    id_espacio INT NOT NULL,
    dia_semana TINYINT NOT NULL COMMENT '1=Lunes, 7=Domingo',
    hora_apertura TIME NOT NULL,
    hora_cierre TIME NOT NULL,
    CONSTRAINT fk_horario_espacio FOREIGN KEY (id_espacio)
        REFERENCES espacio(id_espacio)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_horario_dia CHECK (dia_semana BETWEEN 1 AND 7),
    CONSTRAINT chk_horario_horas CHECK (hora_cierre > hora_apertura)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla 8: reserva
CREATE TABLE IF NOT EXISTS reserva (
    id_reserva INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    id_espacio INT NOT NULL,
    fecha_reserva DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    numero_asistentes INT NOT NULL DEFAULT 1,
    estado_reserva ENUM('pendiente', 'confirmada', 'cancelada', 'completada') NOT NULL DEFAULT 'pendiente',
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_reserva_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_reserva_espacio FOREIGN KEY (id_espacio)
        REFERENCES espacio(id_espacio)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_reserva_horas CHECK (hora_fin > hora_inicio),
    CONSTRAINT chk_reserva_asistentes CHECK (numero_asistentes > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla 9: reembolso_penalizacion
CREATE TABLE IF NOT EXISTS reembolso_penalizacion (
    id_registro INT AUTO_INCREMENT PRIMARY KEY,
    id_reserva INT NOT NULL,
    tipo ENUM('reembolso', 'penalizacion') NOT NULL,
    monto DECIMAL(10,2) NOT NULL,
    motivo VARCHAR(255) NOT NULL,
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_reembolso_reserva FOREIGN KEY (id_reserva)
        REFERENCES reserva(id_reserva)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_reembolso_monto CHECK (monto >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Tabla 10: servicio_adicional
CREATE TABLE IF NOT EXISTS servicio_adicional (
    id_servicio INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    precio_unitario DECIMAL(10,2) NOT NULL,
    descripcion VARCHAR(255) NULL,
    CONSTRAINT chk_servicio_precio CHECK (precio_unitario >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla 11: reserva_servicio
CREATE TABLE IF NOT EXISTS reserva_servicio (
    id_reserva_servicio INT AUTO_INCREMENT PRIMARY KEY,
    id_servicio INT NOT NULL,
    id_reserva INT NOT NULL,
    cantidad INT NOT NULL DEFAULT 1,
    precio_aplicado DECIMAL(10,2) NOT NULL,
    sub_total DECIMAL(10,2) GENERATED ALWAYS AS (cantidad * precio_aplicado) STORED,
    CONSTRAINT fk_reserva_servicio_servicio FOREIGN KEY (id_servicio)
        REFERENCES servicio_adicional(id_servicio)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_reserva_servicio_reserva FOREIGN KEY (id_reserva)
        REFERENCES reserva(id_reserva)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_reserva_servicio_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_reserva_servicio_precio CHECK (precio_aplicado >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla 12: usuario_servicio
CREATE TABLE IF NOT EXISTS usuario_servicio (
    id_usuario_servicio INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    id_servicio INT NOT NULL,
    cantidad INT NOT NULL DEFAULT 1,
    precio_aplicado DECIMAL(10,2) NOT NULL,
    sub_total DECIMAL(10,2) GENERATED ALWAYS AS (cantidad * precio_aplicado) STORED,
    fecha_contratacion DATE NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT fk_usuario_servicio_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_usuario_servicio_servicio FOREIGN KEY (id_servicio)
        REFERENCES servicio_adicional(id_servicio)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_usuario_servicio_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_usuario_servicio_precio CHECK (precio_aplicado >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla 13: factura
CREATE TABLE IF NOT EXISTS factura (
    id_factura INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    id_empresa INT NULL,
    fecha_emision DATE NOT NULL DEFAULT (CURRENT_DATE),
    fecha_vencimiento DATE NOT NULL,
    monto_total DECIMAL(10,2) NOT NULL,
    recargo DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    saldo_pendiente DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    tipo_concepto VARCHAR(50) NOT NULL,
    estado_factura ENUM('pendiente', 'pagada', 'anulada') NOT NULL DEFAULT 'pendiente',
    motivo_anulacion VARCHAR(255) NULL,
    CONSTRAINT fk_factura_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_factura_empresa FOREIGN KEY (id_empresa)
        REFERENCES empresa(id_empresa)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_factura_monto CHECK (monto_total >= 0),
    CONSTRAINT chk_factura_recargo CHECK (recargo >= 0),
    CONSTRAINT chk_factura_saldo CHECK (saldo_pendiente >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla 14: detalle_factura
CREATE TABLE IF NOT EXISTS detalle_factura (
    id_detalle INT AUTO_INCREMENT PRIMARY KEY,
    id_factura INT NOT NULL,
    id_membresia INT NULL,
    id_reserva INT NULL,
    id_usuario_servicio INT NULL,
    descripcion VARCHAR(255) NOT NULL,
    monto DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_detalle_factura FOREIGN KEY (id_factura)
        REFERENCES factura(id_factura)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_detalle_membresia FOREIGN KEY (id_membresia)
        REFERENCES membresia(id_membresia)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_detalle_reserva FOREIGN KEY (id_reserva)
        REFERENCES reserva(id_reserva)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_detalle_usuario_servicio FOREIGN KEY (id_usuario_servicio)
        REFERENCES usuario_servicio(id_usuario_servicio)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_detalle_monto CHECK (monto >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla 15: pago
CREATE TABLE IF NOT EXISTS pago (
    id_pago INT AUTO_INCREMENT PRIMARY KEY,
    id_factura INT NOT NULL,
    id_usuario INT NOT NULL,
    fecha_pago DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    monto DECIMAL(10,2) NOT NULL,
    metodo_pago ENUM('efectivo', 'tarjeta', 'transferencia', 'paypal') NOT NULL,
    estado_pago ENUM('pagado', 'pendiente', 'cancelado') NOT NULL DEFAULT 'pagado',
    CONSTRAINT fk_pago_factura FOREIGN KEY (id_factura)
        REFERENCES factura(id_factura)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_pago_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_pago_monto CHECK (monto > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla 16: control_acceso
CREATE TABLE IF NOT EXISTS control_acceso (
    id_acceso INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NULL,
    id_reserva INT NULL,
    fecha_hora_entrada DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_hora_salida DATETIME NULL,
    metodo_acceso ENUM('QR', 'RFID') NOT NULL,
    codigo_leido VARCHAR(255) NOT NULL,
    estado_acceso ENUM('permitido', 'rechazado') NOT NULL DEFAULT 'permitido',
    motivo_rechazo VARCHAR(255) NULL,
    CONSTRAINT fk_acceso_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_acceso_reserva FOREIGN KEY (id_reserva)
        REFERENCES reserva(id_reserva)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla 17: log_auditoria
CREATE TABLE IF NOT EXISTS log_auditoria (
    id_log INT AUTO_INCREMENT PRIMARY KEY,
    tabla_afectada VARCHAR(50) NOT NULL,
    operacion VARCHAR(20) NOT NULL,
    fecha_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usuario_bd VARCHAR(100) NOT NULL DEFAULT (CURRENT_USER()),
    descripcion TEXT NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ÍNDICES DE RENDIMIENTO DE BÚSQUEDA SECUNDARIA

CREATE INDEX idx_usuario_documento ON usuario(numero_documento);
CREATE INDEX idx_usuario_empresa ON usuario(id_empresa);
CREATE INDEX idx_reserva_fecha_hora ON reserva(fecha_reserva, hora_inicio, hora_fin);
CREATE INDEX idx_factura_usuario_estado ON factura(id_usuario, estado_factura);
CREATE INDEX idx_acceso_usuario_fecha ON control_acceso(id_usuario, fecha_hora_entrada);
