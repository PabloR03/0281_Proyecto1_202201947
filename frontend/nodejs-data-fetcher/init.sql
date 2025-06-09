-- Crear tabla para métricas de CPU
CREATE TABLE IF NOT EXISTS cpu_metrics (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    porcentaje_uso DECIMAL(5,2) NOT NULL DEFAULT 0,
    raw_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Crear tabla para métricas de RAM
CREATE TABLE IF NOT EXISTS ram_metrics (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    total_mb BIGINT NOT NULL DEFAULT 0,
    libre_mb BIGINT NOT NULL DEFAULT 0,
    uso_mb BIGINT NOT NULL DEFAULT 0,
    porcentaje_uso DECIMAL(5,2) NOT NULL DEFAULT 0,
    raw_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Crear índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_cpu_metrics_timestamp ON cpu_metrics(timestamp);
CREATE INDEX IF NOT EXISTS idx_ram_metrics_timestamp ON ram_metrics(timestamp);
CREATE INDEX IF NOT EXISTS idx_cpu_metrics_created_at ON cpu_metrics(created_at);
CREATE INDEX IF NOT EXISTS idx_ram_metrics_created_at ON ram_metrics(created_at);
