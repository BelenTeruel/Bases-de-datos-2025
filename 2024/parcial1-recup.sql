-- Creo la data base 
source /home/bblen/Descargas/01-airbnb-like-schema.sql;

-- inserto data
source /home/bblen/Descargas/01-airbnb-like-schema.sql;


-- CONSIGNAS 
-- 1. Obtener los usuarios que han gastado mas en reservas. 
SELECT 
    u.id AS id_usuario,
    u.name AS Nombre,
    SUM(p.amount) AS total_gastado
FROM users u
INNER JOIN payments p ON u.id = p.user_id 
GROUP BY u.id
ORDER BY total_gastado DESC;

-- otra forma
SELECT 
    p.user_id AS id_usuario,
    u.name AS Nombre,
    SUM(p.amount) AS total_gastado
FROM payments p
    JOIN users u ON u.id = p.user_id 
GROUP BY p.user_id
ORDER BY total_gastado DESC;

-- 2. Obtener las 10 propiedades con el mayor ingreso por reservas.
SELECT 
    b.property_id AS Id_prop,
    p.name AS Propiedad,
    sum(b.total_price) AS Ingreso_total
FROM bookings b
INNER JOIN properties p ON p.id = b.property_id
GROUP BY b.property_id
ORDER BY Ingreso_total DESC
LIMIT 10;


-- 3. Crear un trigger para registrar automaticamente resenas negativas en la tabla de mensajes. 
--    Es decir, el owner recibe un mensaje al obtener un review menor o igual a 2. 
DELIMITER $$
CREATE TRIGGER negative_rvw 
AFTER INSERT ON reviews 
FOR EACH ROW 
BEGIN  
    DECLARE owner_id INT;

    IF( NEW.rating <= 2 ) THEN 
        SELECT p.owner_id into owner_id
        FROM properties p 
        WHERE p.id = NEW.property_id;

        INSERT INTO messages (sender_id, receiver_id, property_id, content)
        VALUES (NEW.user_id,owner_id, NEW.property_id, 'Bad review received');
    END IF;
END $$
DELIMITER ;

-- pruebo
-- INSERT INTO airbnb_like_db.reviews (id,booking_id,user_id,property_id,rating,comment,created_at) VALUES
-- (1302,1351,1741,1697,2,"HOLA HOLA HOLA","2024-10-02 16:24:45.673354");






-- 4. Crear un procedimiento llamado process_payment que :
--      Recibe los siguientes parametros: 
--              input_booking_id (INT): El ID de la reserva.
--              input_user_id (INT): El ID del usuario que realiza el pago
--              input_amount (NUMERICO): El monto del pago.
--              input_payment_method (VARCHAR): El metodo de pago utilizado (por ej. "credit_card", "paypal")

    -- Requisitios: 
        -- Verif si la reserva asociada existe y esta en estado "confirmed", 
        -- insertar un nuevo registro en la tabla payments. 
        -- Actualizar el estado de la reserva a "paid". 
    
    -- No es necesario manejar errores ni transacciones en este procedimiento. 



DROP PROCEDURE IF EXISTS process_payment;
