
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
   



**Cuándo ANIDAR (Embed)**

Para relaciones "uno-a-uno" o "uno-a-pocos" 

- Principio clave: "Datos que se acceden juntos, deben almacenarse juntos".
- Ventaja: Muy rápido para leer (una sola consulta trae todo).
- Desventaja: Peligroso si el "lado pocos" puede crecer sin límite (riesgo de 16MB).
*Ejemplo: Los items (items) dentro de un pedido (order). Un pedido tiene una cantidad limitada de items y casi siempre querrás ver los items junto con el pedido.*


**Cuándo REFERENCIAR (Reference)**

Para relaciones "uno-a-muchos-ilimitados" o "muchos-a-muchos" 

- Principio clave: "Usar cuando los datos crecen sin límite o se consultan por separado".
- Ventaja: Evita el límite de 16MB por documento.
- Desventaja: Requiere una segunda consulta (o un $lookup) para obtener los datos relacionados, lo cual es más lento.

*Ejemplo: Los comentarios (comments) de una película (movie). Una película puede tener miles de comentarios (ilimitados) y a menudo querrás cargarlos de forma paginada (de 20 en 20), no todos juntos.*





Lista de los valores más comunes que puedes usar en el campo bsonType para la validación de esquemas.

*Tipos Numéricos*

    "double": Para números de punto flotante (decimales, el tipo numérico por defecto en JavaScript).
    "int": Para números enteros de 32 bits (ej. NumberInt(30)).
    "long": Para números enteros de 64 bits (ej. NumberLong(1234567890)).
    "decimal": Para números decimales de alta precisión (tipo Decimal128).

*Tipos Comunes*

    "string": Para cadenas de texto.
    "bool": Para valores booleanos (true o false).
    "null": Para el valor null.

*Tipos Estructurales*

    "object": Para un sub-documento o documento anidado.
    "array": Para un arreglo (lista) de valores.

*Tipos de Identificador y Fecha*

    "objectId": Para el tipo ObjectId de MongoDB.
    "date": Para el tipo ISODate de MongoDB.
    "timestamp": Para el tipo Timestamp interno de MongoDB.

*Tipos de Datos Binarios*

    "binData": Para datos binarios (como imágenes o archivos).


*Uso Importante: Arreglo de Tipos*
Recuerda que también puedes usar un arreglo de strings si quieres que un campo acepte más de un tipo.

```
    telefono: {
        bsonType: ["string", "null"]
    }
    
```


