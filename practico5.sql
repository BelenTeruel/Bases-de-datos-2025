
------------------------------------------------------------------------------------------------------


-- PRACTICO 5 Joins y Conjuntos


------------------------------------------------------------------------------------------------------


--1.  Cree una tabla de `directors` con las columnas: Nombre, Apellido, Número de Películas.
CREATE TABLE directors (
    Nombre VARCHAR (50),
    Apellido VARCHAR (50),
    Numero_de_peliculas INT
);

-- 2. El top 5 de actrices y actores de la tabla `actors` que tienen la mayor experiencia 
-- (i.e. el mayor número de películas filmadas) son también directores de las películas en las que participaron. 
-- Basados en esta información, inserten, utilizando una subquery los valores correspondientes en la tabla `directors`.

INSERT INTO directors (Nombre, Apellido, Numero_de_peliculas)
SELECT 
    a.first_name AS Nombre,
    a.last_name AS Apellido,
    COUNT(fa.film_id) AS Numero_de_peliculas
FROM actor a
INNER JOIN film_actor fa ON a.actor_id = fa.actor_id
GROUP BY a.actor_id
ORDER BY Numero_de_peliculas DESC
LIMIT 5;


-- 3 Agregue una columna `premium_customer` que tendrá un valor 'T' o 'F' 
-- de acuerdo a si el cliente es "premium" o no. Por defecto ningún cliente será premium.
ALTER TABLE customer ADD premium_customer BOOLEAN DEFAULT FALSE;


-- 4 Modifique la tabla customer. Marque con 'T' en la columna `premium_customer` 
-- de los 10 clientes con mayor dinero gastado en la plataforma

UPDATE customer 
SET premium_customer = 'T'
WHERE customer_id IN (
    SELECT customer_id 
    FROM (
        SELECT 
            p.customer_id
        FROM payment p
        INNER JOIN rental r ON p.rental_id = r.rental_id 
        GROUP BY p.customer_id
        ORDER BY SUM(p.amount) DESC
        LIMIT 10
    ) AS top_customers
);

-- USANDO PROC 
CREATE PROCEDURE UpdatePremiumCustomer ()
BEGIN 
    UPDATE customer SET premium_customer = FALSE;
    UPDATE customer SET premium_customer = TRUE
    WHERE customer_id IN (
        SELECT customer_id 
        FROM (
            SELECT 
                p.customer_id
            FROM payment p
            INNER JOIN rental r ON p.rental_id = r.rental_id 
            GROUP BY p.customer_id
            ORDER BY SUM(p.amount) DESC
            LIMIT 10
        ) AS top_customers
    );
END 


-- 5 Listar, ordenados por cantidad de películas (de mayor a menor), 
-- los distintos ratings de las películas existentes
--  (Hint: rating se refiere en este caso a la clasificación según edad: G, PG, R, etc).



-- 6 ¿Cuáles fueron la primera y última fecha donde hubo pagos?
(SELECT p.payment_date FROM payment p ORDER BY p.payment_date ASC LIMIT 1)
UNION 
(SELECT p.payment_date FROM payment p ORDER BY p.payment_date DESC LIMIT 1);


-- 7 Calcule, por cada mes, el promedio de pagos (Hint: vea la manera de extraer el nombre del mes de una fecha).

SELECT 
    YEAR (p.payment_date) AS Año,
    MONTHNAME(p.payment_date) AS Mes,
    AVG(p.amount) AS Promedio_pago_mensual
FROM payment p 
GROUP BY YEAR(p.payment_date), MONTHNAME(p.payment_date)
ORDER BY YEAR(p.payment_date), MONTHNAME(p.payment_date);


-- 8  Listar los 10 distritos que tuvieron mayor cantidad de alquileres (con la cantidad total de alquileres).




-- 9 Modifique la table `inventory` agregando una columna `stock` que sea un número entero y representa
--  la cantidad de copias de una misma película que tiene determinada tienda. El número por defecto debería ser 5 copias.

ALTER TABLE inventory ADD stock INT DEFAULT 5;

-- Procedimiento para actualizar el stock basado en el conteo real de copias por película y tienda

-- OPCIÓN 1: Subconsulta correlacionada (Original)

CREATE PROCEDURE UpdateMovieStock_V1()
BEGIN 
    UPDATE inventory i1 
    SET i1.stock = (
        SELECT COUNT(*) 
        FROM inventory i2 
        WHERE i2.film_id = i1.film_id 
        AND i2.store_id = i1.store_id
    );
END 

-- OPCIÓN 2: Usando JOIN con tabla temporal

CREATE PROCEDURE UpdateMovieStock_V2()
BEGIN 
    UPDATE inventory i
    INNER JOIN (
        SELECT 
            film_id, 
            store_id, 
            COUNT(*) as total_copies
        FROM inventory 
        GROUP BY film_id, store_id
    ) as stock_count 
    ON i.film_id = stock_count.film_id 
    AND i.store_id = stock_count.store_id
    SET i.stock = stock_count.total_copies;
END

-- OPCIÓN 3: Usando Window Function (MySQL 8.0+)

CREATE PROCEDURE UpdateMovieStock_V3()
BEGIN 
    UPDATE inventory i1
    INNER JOIN (
        SELECT 
            inventory_id,
            COUNT(*) OVER (PARTITION BY film_id, store_id) as stock_count
        FROM inventory
    ) as windowed_stock
    ON i1.inventory_id = windowed_stock.inventory_id
    SET i1.stock = windowed_stock.stock_count;
END 
 

-- OPCIÓN 4: Resetear a 5 y luego actualizar solo los que no tienen 5 copias

CREATE PROCEDURE UpdateMovieStock_V4()
BEGIN 
    -- Primero, establecer todo a 5 (valor por defecto)
    UPDATE inventory SET stock = 5;
    
    -- Luego actualizar solo aquellos que no tienen 5 copias
    UPDATE inventory i1 
    SET i1.stock = (
        SELECT COUNT(*) 
        FROM inventory i2 
        WHERE i2.film_id = i1.film_id 
        AND i2.store_id = i1.store_id
    )
    WHERE (
        SELECT COUNT(*) 
        FROM inventory i3 
        WHERE i3.film_id = i1.film_id 
        AND i3.store_id = i1.store_id
    ) != 5;
END 



-- 10 Cree un trigger `update_stock` que, cada vez que se agregue un nuevo registro a la tabla rental, 
-- haga un update en la tabla `inventory` restando una copia al stock de la película rentada 
-- (Hint: revisar que el rental no tiene información directa sobre la tienda, sino sobre el cliente, que está asociado a una tienda en particular).

CREATE TRIGGER update_stock 
AFTER INSERT ON rental
FOR EACH ROW
BEGIN
    UPDATE inventory 
    SET stock = stock - 1 
    WHERE inventory_id = NEW.inventory_id
    AND stock > 0;  -- Solo restar si hay stock disponible
END 


-- 11  Cree una tabla `fines` que tenga dos campos: `rental_id` y `amount`. El primero es una clave foránea 
-- a la tabla rental y el segundo es un valor numérico con dos decimales.
CREATE TABLE fines (
    rental_id INT,
    amount DECIMAL(10,2),
    FOREIGN KEY (rental_id) REFERENCES rental(rental_id)
);

-- 12 Cree un procedimiento `check_date_and_fine` que revise la tabla `rental` 
-- y cree un registro en la tabla `fines` por cada `rental` cuya devolución (return_date) haya tardado más de 3 días 
-- (comparación con rental_date). El valor de la multa será el número de días de retraso multiplicado por 1.5.
CREATE PROCEDURE check_date_and_fine 
BEGIN 
    INSERT INTO fines (rental_id, amount)
    SELECT 
        r.rental_id 
        DATEDIFF(r.return_date, r.rental_date) * 1.5
     
    FROM rental r
    WHERE r.return_date IS NOT NULL
    AND DATEDIFF(r.return_date, rental_date) > 3;
END



-- 13  Crear un rol `employee` que tenga acceso de inserción, eliminación y actualización a la tabla `rental`.
CREATE ROLE employee;
GRANT INSERT, UPDATE, DELETE ON sakila.rental TO employee;


-- 14 Revocar el acceso de eliminación a `employee` y crear un rol `administrator` que tenga todos los privilegios sobre la BD `sakila`.
REVOKE DELETE ON sakila.rental FROM employee;
CREATE ROLE administrator;
GRANT ALL PRIVILEGES ON sakila.* TO administrator;


-- 15 Crear dos roles de empleado. A uno asignarle los permisos de `employee` y al otro de `administrator`

-- Crear dos usuarios (empleados)
CREATE USER 'empleado1'@'localhost' IDENTIFIED BY 'password123';
CREATE USER 'empleado2'@'localhost' IDENTIFIED BY 'password456';

-- Asignar el rol employee al primer empleado
GRANT employee TO 'empleado1'@'localhost';

-- Asignar el rol administrator al segundo empleado
GRANT administrator TO 'empleado2'@'localhost';


-- Establecer los roles como predeterminados para que se activen automáticamente
-- SET DEFAULT ROLE employee TO 'empleado1'@'localhost';
-- SET DEFAULT ROLE administrator TO 'empleado2'@'localhost';

-- Opcional: Verificar los roles asignados
-- SHOW GRANTS FOR 'empleado1'@'localhost';
-- SHOW GRANTS FOR 'empleado2'@'localhost';
