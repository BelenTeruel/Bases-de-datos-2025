-- 1. Listar las 7 propiedades con la mayor cantidad de reviews en el año 2024 
SELECT 
    p.id AS id_prop,
    p.name AS Nombre_prop,
    COUNT(r.property_id) AS cantidad_reviews
FROM reviews r
INNER JOIN properties p ON r.property_id = p.id
WHERE YEAR(r.created_at) = '2024'
GROUP BY p.id 
ORDER BY cantidad_reviews DESC
LIMIT 7;


-- 2. obtener los ingresos por reservas de cada propiedad. 
-- Esta consulta debe calcular los ingresos totales generados por cada prop
-- Ayuda: hay un campo `price_per_night` en la tabla `properties` donde 
-- los ingresos totales se computan sumando la cantidad de noches reservadas 
-- para cada reserva multiplicando por el precio por noche

SELECT 
    p.id AS prop_id,
    p.name AS Nombre,
    SUM(DATEDIFF(b.check_out, b.check_in) * p.price_per_night) AS ingreso_total
FROM properties p
INNER JOIN bookings b ON b.property_id = p.id 
GROUP BY p.id 
ORDER BY ingreso_total DESC;
 

-- 3 Listar los principales usuarios segun los pagos totales
-- Esta consulta calcula los pagos totales realizados por cada usuario y enumera
--  los principales 10 usuarios segun la suma de sus pagos
SELECT 
    u.id AS id_user,
    u.name AS Nombre_usuario, 
    SUM(p.amount) AS pago_total
FROM payments p 
INNER JOIN users u ON u.id = p.user_id 
GROUP BY u.id 
ORDER BY pago_total DESC
LIMIT 10;

-- 4, crear un `trigger_host_after_booking` que notifica al anfitrion sobre 
-- una nueva reserva. Es decir, cuando se realiza una reserva, notifique al
-- anfitrion de la propiedad mediante un mensaje
DELIMITER $$
CREATE TRIGGER trigger_host_after_booking 
AFTER INSERT ON bookings
FOR EACH ROW 
BEGIN
    DECLARE owner_id INT;

    SELECT p.owner_id INTO owner_id 
    FROM properties p 
    WHERE p.id = NEW.property_id;

    INSERT INTO messages (sender_id, receiver_id, property_id, content)
    VALUES (NEW.user_id, owner_id, NEW.property_id, 'New booking'); 
END $$
DELIMITER ;

-- pruebo
INSERT INTO airbnb_like_db.bookings (id,property_id,user_id,check_in,check_out,total_price,status,created_at) VALUES
(1402,1619,1747,"2024-11-29","2024-12-12",4838.0,"confirmed","2024-10-02 16:24:45.643120");


-- 5. Crear un procedimiento `add_new_booking` para agregar una nueva reserva. 
-- Este procedimiento agrega una nueva reserva para un usuario, segun el ID de la prop
-- el ID del usuario y las fechas de entrada y salida. 
-- Verif si la prop esta disponible durante las fechas especificadas antes de insertar la reserva

DROP PROCEDURE IF EXISTS add_new_booking;

DELIMITER $$ 
CREATE PROCEDURE add_new_booking (
    IN input_id_prop INT, 
    IN input_id_user INT, 
    IN input_check_in DATE, 
    IN input_check_out DATE
)
BEGIN 
    DECLARE conflictos INT DEFAULT 0;
    DECLARE prop_price DECIMAL(10,2) DEFAULT 0;
    DECLARE total_nights INT DEFAULT 0;
    DECLARE total_price DECIMAL(10,2) DEFAULT 0;
    DECLARE prop_exists INT DEFAULT 0;

    SELECT COUNT(*) INTO prop_exists
    FROM properties 
    WHERE id = input_id_prop;

    IF (prop_exists = 0) THEN
        SELECT 'Error: La propiedad no existe' AS resultado;
    ELSE

        SELECT COUNT(*) INTO conflictos
        FROM bookings 
        WHERE property_id = input_id_prop 
          AND status IN ('confirmed', 'pending')  
          AND NOT (input_check_out <= check_in OR input_check_in >= check_out);

        IF (conflictos = 0) THEN
            SELECT p.price_per_night INTO prop_price
            FROM properties p 
            WHERE p.id = input_id_prop;
            
            SET total_nights = DATEDIFF(input_check_out, input_check_in);
            SET total_price = total_nights * IFNULL(prop_price, 0);
            

            INSERT INTO bookings (property_id, user_id, check_in, check_out, total_price, status, created_at)
            VALUES (input_id_prop, input_id_user, input_check_in, input_check_out, total_price, 'confirmed', NOW());
            
            SELECT 'Reserva creada exitosamente' AS resultado, 
                   total_nights AS noches, 
                   prop_price AS precio_por_noche, 
                   total_price AS precio_total;
        
        ELSE
            SELECT 'Error: La propiedad no está disponible en esas fechas' AS resultado, 
                   conflictos AS reservas_conflictivas;
        
        END IF;
    END IF;
END $$
DELIMITER ;

-- pruebo
CALL add_new_booking(1603, 1800, '2025-12-15', '2025-12-20');


-- 6. Crear el rol `admin` y asignarle permisos de creacion sobre la tabla `properties` y permiso
-- de actualizacion sobre la columna `status` de la tabla `property_availability`

CREATE ROLE IF NOT EXISTS 'admin';
-- GRANT CREATE ON airbnb_like_db.* TO 'admin';
GRANT INSERT ON airbnb_like_db.properties TO 'admin';
GRANT UPDATE (status) ON airbnb_like_db.property_availability TO 'admin';








-- Si quieres que el trigger también se active en UPDATEs, crea este trigger adicional:
DELIMITER $$
CREATE TRIGGER trigger_host_after_booking_update 
AFTER UPDATE ON bookings
FOR EACH ROW 
BEGIN
    DECLARE owner_id INT;

    SELECT p.owner_id INTO owner_id 
    FROM properties p 
    WHERE p.id = NEW.property_id;

    -- Corregido: especificamos las columnas correctamente
    INSERT INTO messages (sender_id, receiver_id, property_id, content)
    VALUES (NEW.user_id, owner_id, NEW.property_id, 'Booking updated'); 
END $$
DELIMITER ;


-- Ejemplos de UPDATE en bookings (el trigger actual NO se activará)
-- UPDATE para cambiar el status de una reserva
UPDATE airbnb_like_db.bookings 
SET status = 'cancelled' 
WHERE id = 1302;

-- UPDATE para cambiar las fechas de una reserva
UPDATE airbnb_like_db.bookings 
SET check_in = '2024-11-26', check_out = '2024-11-30', total_price = 200.0
WHERE id = 1303;


-- valores que estaban antes
-- (1302,1619,1747,"2024-11-29","2024-12-12",4838.0,"confirmed","2024-10-02 16:24:45.64312"),
-- (1303,1666,1836,"2024-10-26","2024-10-30",159.0,"confirmed","2024-10-02 16:24:45.644124"),


