
-- Estas dos consultas son equivalentes:
SELECT * FROM table WHERE col = SOME (SELECT ...);    -- Igual a ALGUNO
SELECT * FROM table WHERE col IN (SELECT ...);

SELECT * FROM table WHERE col <> SOME (SELECT ...);  -- Al menos uno diferente

-- Estas dos consultas son equivalentes:
SELECT * FROM table WHERE col <> ALL (SELECT ...);    -- Distinto a todos
SELECT * FROM table WHERE col NOT IN (SELECT ...);
SELECT * FROM table WHERE col = ALL (SELECT ...);  -- Igual a TODOS




Tipo de Trigger	    NEW	             OLD	                  Uso
INSERT	        ✅ Disponible	    ❌ No existe            	NEW.campo
UPDATE	        ✅ Valores nuevos	✅ Valores anteriores	NEW.campo, OLD.campo
DELETE	        ❌ No existe        	✅ Disponible	        OLD.campo
   