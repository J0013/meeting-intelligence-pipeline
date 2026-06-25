-- =============================================================================
-- VÍNCULO HILO ↔ RESUMEN  (Flujo 1 -> Flujo A)
-- =============================================================================
-- Tabla nueva `hilos_resumen` (NO columnas en transcripciones): la transcripción
-- es la VERDAD INMUTABLE; no le colgamos metadatos mutables de correo. Además
-- 1 transcripción puede reenviarse -> varios hilos.
--
-- Tipos alineados con transcripciones (verificado):
--   transcripciones.id        = INTEGER
--   transcripciones.cliente_id = TEXT
-- =============================================================================

CREATE TABLE IF NOT EXISTS hilos_resumen (
  id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  transcripcion_id INTEGER NOT NULL REFERENCES transcripciones(id) ON DELETE CASCADE,
  cliente_id       TEXT   NOT NULL,
  gmail_thread_id  TEXT   NOT NULL,            -- threadId del correo de resumen enviado
  gmail_message_id TEXT,                       -- id del mensaje enviado (opcional)
  enviado_a        TEXT,                       -- destinatario del resumen
  creado_en        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Un hilo apunta a una sola transcripción -> evita duplicados al registrar.
CREATE UNIQUE INDEX IF NOT EXISTS uq_hilos_resumen_thread
  ON hilos_resumen (gmail_thread_id);

CREATE INDEX IF NOT EXISTS idx_hilos_resumen_transcripcion
  ON hilos_resumen (transcripcion_id);

-- =============================================================================
-- AÑADIDO AL FLUJO 1 (no reescribir el flujo entero, solo añadir UN nodo)
-- =============================================================================
-- Después del nodo Gmail que ENVÍA el resumen (su salida trae `id` y `threadId`),
-- añade un nodo Postgres (executeQuery) con esta consulta:
--
--   INSERT INTO hilos_resumen (transcripcion_id, cliente_id, gmail_thread_id, gmail_message_id, enviado_a)
--   VALUES ($1, $2, $3, $4, $5)
--   ON CONFLICT (gmail_thread_id) DO NOTHING;
--
-- Query Parameters (en este orden):
--   $1 = id de la transcripción recién guardada   (referencia el nodo donde la insertaste)
--   $2 = cliente_id  (TEXT)
--   $3 = {{ $json.threadId }}      (del nodo Gmail "send")
--   $4 = {{ $json.id }}            (del nodo Gmail "send")
--   $5 = email del destinatario
--
-- Eso es todo lo que cambia en el Flujo 1.
-- =============================================================================
