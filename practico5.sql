
--1.  Cree una tabla de `directors` con las columnas: Nombre, Apellido, Número de Películas.
CREATE TABLE directors (
    Nombre VARCHAR (50),
    Apellido VARCHAR (50),
    Numero_de_peliculas INT,
)

-- 2. El top 5 de actrices y actores de la tabla `actors` que tienen la mayor experiencia 
-- (i.e. el mayor número de películas filmadas) son también directores de las películas en las que participaron. 
-- Basados en esta información, inserten, utilizando una subquery los valores correspondientes en la tabla `directors`.



-- 3 Agregue una columna `premium_customer` que tendrá un valor 'T' o 'F' 
-- de acuerdo a si el cliente es "premium" o no. Por defecto ningún cliente será premium.



-- 4 Modifique la tabla customer. Marque con 'T' en la columna `premium_customer` 
-- de los 10 clientes con mayor dinero gastado en la plataforma


-- 5 Listar, ordenados por cantidad de películas (de mayor a menor), 
-- los distintos ratings de las películas existentes
--  (Hint: rating se refiere en este caso a la clasificación según edad: G, PG, R, etc).


-- 6 ¿Cuáles fueron la primera y última fecha donde hubo pagos?


-- 7 Calcule, por cada mes, el promedio de pagos (Hint: vea la manera de extraer el nombre del mes de una fecha).



-- 8  Listar los 10 distritos que tuvieron mayor cantidad de alquileres (con la cantidad total de alquileres).


-- 9 Modifique la table `inventory_id` agregando una columna `stock` que sea un número entero y representa
--  la cantidad de copias de una misma película que tiene determinada tienda. El número por defecto debería ser 5 copias.



-- 10 Cree un trigger `update_stock` que, cada vez que se agregue un nuevo registro a la tabla rental, 
-- haga un update en la tabla `inventory` restando una copia al stock de la película rentada 
-- (Hint: revisar que el rental no tiene información directa sobre la tienda, sino sobre el cliente, que está asociado a una tienda en particular).



-- 11  Cree una tabla `fines` que tenga dos campos: `rental_id` y `amount`. El primero es una clave foránea 
-- a la tabla rental y el segundo es un valor numérico con dos decimales.


-- 12 Cree un procedimiento `check_date_and_fine` que revise la tabla `rental` 
-- y cree un registro en la tabla `fines` por cada `rental` cuya devolución (return_date) haya tardado más de 3 días 
-- (comparación con rental_date). El valor de la multa será el número de días de retraso multiplicado por 1.5.



-- 13  Crear un rol `employee` que tenga acceso de inserción, eliminación y actualización a la tabla `rental`.



-- 14 Revocar el acceso de eliminación a `employee` y crear un rol `administrator` que tenga todos los privilegios sobre la BD `sakila`.



-- 15 Crear dos roles de empleado. A uno asignarle los permisos de `employee` y al otro de `administrator`

