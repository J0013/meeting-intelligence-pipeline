-- ============================================================
-- Meeting Intelligence Pipeline — esquema de base de datos
-- PostgreSQL 16 · solo estructura, SIN datos.
--
-- Refleja la tabla sobre la que opera el workflow de n8n
-- (workflow/workflow.json). El hash SHA-256 se calcula en la propia
-- inserción con pgcrypto y la columna UNIQUE da idempotencia.
-- ============================================================

-- digest()/encode() para el hash SHA-256 vienen de pgcrypto.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS transcripciones (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- Identificación del cliente (datos genéricos, sin PII real en la demo).
    cliente_id      TEXT        NOT NULL,
    cliente_nombre  TEXT,
    cliente_ceo     TEXT,

    -- Datos de la reunión.
    fecha_reunion   DATE,
    asunto          TEXT,
    transcripcion   TEXT,                 -- transcripción literal
    resumen         TEXT,                 -- resumen estructurado

    -- Deduplicación: hash SHA-256 del contenido.
    -- UNIQUE → "ON CONFLICT (content_hash) DO NOTHING" hace el flujo idempotente:
    -- una misma reunión nunca se inserta dos veces.
    content_hash    TEXT        NOT NULL UNIQUE,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- La comprobación de duplicado es el camino caliente.
CREATE INDEX IF NOT EXISTS idx_transcripciones_content_hash ON transcripciones (content_hash);

-- Filtro por fecha para futuras agregaciones (semanal/mensual/anual).
CREATE INDEX IF NOT EXISTS idx_transcripciones_fecha ON transcripciones (fecha_reunion);
