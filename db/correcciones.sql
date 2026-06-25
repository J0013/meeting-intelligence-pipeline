-- =============================================================================
-- CORRECCIONES (log inmutable)  —  Workflow A
-- =============================================================================
-- La transcripción cruda NO se toca. Esto es una CAPA aparte de correcciones.
-- Tipos alineados con transcripciones (verificado):
--   transcripciones.id        = INTEGER
--   transcripciones.cliente_id = TEXT
-- =============================================================================

CREATE TABLE IF NOT EXISTS correcciones (
  id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  transcripcion_id INTEGER NOT NULL REFERENCES transcripciones(id) ON DELETE CASCADE,
  cliente_id       TEXT NOT NULL,              -- aislamiento multi-tenant
  texto_erroneo    TEXT NOT NULL,
  texto_correcto   TEXT NOT NULL,
  tipo             TEXT,                        -- 'persona' | 'variedad' | 'sitio' | 'otro'
  autor            TEXT,                        -- email del que corrige
  creado_en        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Diccionario que aprende: encontrar correcciones recurrentes por cliente.
-- Permite, en el futuro, auto-corregir futuras transcripciones consultando:
--   SELECT texto_erroneo, texto_correcto, count(*) AS veces
--   FROM correcciones
--   WHERE cliente_id = $1
--   GROUP BY texto_erroneo, texto_correcto
--   HAVING count(*) >= 2
--   ORDER BY veces DESC;
CREATE INDEX IF NOT EXISTS idx_correcciones_diccionario
  ON correcciones (cliente_id, texto_erroneo);

CREATE INDEX IF NOT EXISTS idx_correcciones_transcripcion
  ON correcciones (transcripcion_id);
