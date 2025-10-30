-- 1.Devuelva la oficina con mayor número de empleados.
SELECT 
    officeCode AS Oficina,
    COUNT(employeeNumber) AS cantidad_empleados
FROM employees
GROUP BY officeCode
ORDER BY cantidad_empleados DESC
LIMIT 1; 


-- 2. ¿Cuál es el promedio de órdenes hechas por oficina?, 
-- ¿Qué oficina vendió la mayor cantidad de productos?


-- 3. Devolver el valor promedio, máximo y mínimo de pagos que se hacen por mes.
SELECT
    YEAR(paymentDate) AS anio,
    MONTHNAME(paymentDate) AS Mes,
    AVG(amount) AS pago_promedio,
    MAX(amount) AS pago_max,
    MIN(amount) AS pago_min
FROM payments 
GROUP BY YEAR(paymentDate), MONTHNAME(paymentDate)
ORDER BY anio, MONTH(paymentDate);


-- 4. Crear un procedimiento "Update Credit" en donde se modifique el límite de 
-- crédito de un cliente con un valor pasado por parámetro.
DELIMITER $$
CREATE PROCEDURE UpdateCredit (IN input_customerNumber INT, IN input_credit_limit DECIMAL(10,2)) 
BEGIN
    UPDATE customers 
    SET creditLimit = input_credit_limit
    WHERE customerNumber = input_customerNumber;
END $$
DELIMITER ;


-- 5.Cree una vista "Premium Customers" que devuelva el top 10 de clientes 
-- que más dinero han gastado en la plataforma. La vista deberá devolver 
-- el nombre del cliente, la ciudad y el total gastado por ese cliente en la plataforma.

CREATE VIEW PremiumCustomers AS 
SELECT 
    c.customerNumber,
    c.customerName AS Nombre, 
    c.city AS Ciudad,
    SUM(p.amount) AS total_gastado
FROM payments p
INNER JOIN customers c ON p.customerNumber = c.customerNumber 
GROUP BY c.customerNumber;

-- Para obtener el TOP 10, usar la vista así:
SELECT * FROM PremiumCustomers ORDER BY total_gastado DESC LIMIT 10;


-- 6. Cree una función "employee of the month" que tome un mes y un año y 
-- devuelve el empleado (nombre y apellido) cuyos clientes hayan efectuado 
-- la mayor cantidad de órdenes en ese mes.

DELIMITER $$
CREATE FUNCTION employee_of_the_month (input_month INT, input_year INT) 
RETURNS VARCHAR(100)
READS SQL DATA
DETERMINISTIC
BEGIN 
    DECLARE nombre VARCHAR (15);
    DECLARE apellido VARCHAR(15);
    DECLARE cant_ordenes INT;
    DECLARE result VARCHAR(100);

    SELECT 
        e.firstName AS Nombre,
        e.lastName AS Apellido,
        COUNT(o.orderNumber) AS cantidad_ordenes
    INTO 
        nombre,
        apellido,
        cant_ordenes
    
    FROM orders o
    INNER JOIN customers c ON o.customerNumber = c.customerNumber 
    INNER JOIN employees e ON e.employeeNumber = c.salesRepEmployeeNumber

    WHERE MONTH(o.orderDate) = input_month AND YEAR(o.orderDate) = input_year

    GROUP BY e.employeeNumber
    ORDER BY cantidad_ordenes DESC
    LIMIT 1;

    IF nombre IS NOT NULL THEN 
        SET result = CONCAT(nombre, ' ', apellido);
    ELSE 
        SET result = 'No employee found';
    END IF;

    RETURN result;

END $$
DELIMITER ;


-- ejecuto: 
-- SELECT employee_of_the_month(1, 2005) AS resultado;

-- Para chequear:
-- SELECT 
--     CONCAT(e.firstName, ' ', e.lastName) as empleado,
--     COUNT(o.orderNumber) as ordenes_totales
-- FROM employees e
-- JOIN customers c ON e.employeeNumber = c.salesRepEmployeeNumber
-- JOIN orders o ON c.customerNumber = o.customerNumber
-- WHERE MONTH(o.orderDate) = 1 AND YEAR(o.orderDate) = 2005
-- GROUP BY e.employeeNumber
-- ORDER BY ordenes_totales DESC;




-- 7. Crear una nueva tabla "Product Refillment". Deberá tener una relación 
-- varios a uno con "products" y los campos: `refillmentID`, `productCode`, `orderDate`, `quantity`.

CREATE TABLE Product_refillment (
    refillmentID INT AUTO_INCREMENT,
    productCode VARCHAR(15) NOT NULL, 
    orderDate DATE NOT NULL, 
    quantity INT NOT NULL,
    PRIMARY KEY (`refillmentID`),
    CONSTRAINT `prod_reff_ibfk_1` FOREIGN KEY (`productCode`) REFERENCES `products` (`productCode`)
);


-- 8.Definir un trigger "Restock Product" que esté pendiente de los cambios efectuados 
-- en `orderdetails` y cada vez que se agregue una nueva orden revise la cantidad de 
-- productos pedidos (`quantityOrdered`) y compare con la cantidad en stock 
-- (`quantityInStock`) y si es menor a 10 genere un pedido en la tabla
--  "Product Refillment" por 10 nuevos productos.

DELIMITER $$
CREATE TRIGGER restock_product 
AFTER INSERT ON orderdetails
FOR EACH ROW
BEGIN 

    DECLARE current_stock INT;
    DECLARE new_stock_after_order INT;

    SELECT quantityInStock INTO current_stock
    FROM products 
    WHERE productCode = NEW.productCode;

    SET new_stock_after_order = current_stock - NEW.quantityOrdered;

    IF (new_stock_after_order < 10) THEN
        INSERT INTO Product_refillment VALUES (NEW.productCode, NOW(), 10);
    END IF;
END $$
DELIMITER ;



-- 9.Crear un rol "Empleado" en la BD que establezca accesos de lectura 
-- a todas las tablas y accesos de creación de vistas.
CREATE ROLE employee;
GRANT ALL PRIVILEGES ON classicmodels.* TO employee;



-- ADICIONALES

-- 1 Encontrar, para cada cliente de aquellas ciudades que comienzan por 'N', 
-- la menor y la mayor diferencia en días entre las fechas de sus pagos. 
-- No mostrar el id del cliente, sino su nombre y el de su contacto.

SELECT 
    c.customerName AS Nombre,
    concat(c.contactFirstName, ' ', c.contactLastName) AS Contacto,
    MAX(DATEDIFF(p2.paymentDate, p1.paymentDate )) AS Mayor_diferencia_dias,
    MIN(DATEDIFF(p2.paymentDate, p1.paymentDate )) AS Menor_diferencia_dias
FROM customers c
INNER JOIN payments p1 ON c.customerNumber = p1.customerNumber
INNER JOIN payments p2 ON c.customerNumber = p2.customerNumber
WHERE c.city LIKE 'N%'
AND p1.paymentDate < p2.paymentDate
GROUP BY c.customerNumber
ORDER BY c.customerName;


-- 2 Encontrar el nombre y la cantidad vendida total de los 10 productos más vendidos
--  que, a su vez, representen al menos el 4% del total de productos, 
-- contando unidad por unidad, de todas las órdenes donde intervienen. 
-- No utilizar LIMIT.


WITH ventas AS (
    SELECT 
        p.productName,
        SUM(od.quantityOrdered) AS total_vendido
    FROM products p
    JOIN orderdetails od ON p.productCode = od.productCode
    GROUP BY p.productName
),
total AS (
    SELECT SUM(total_vendido) AS total_global FROM ventas
),
top10 AS (
    SELECT v.productName, v.total_vendido,
           ROW_NUMBER() OVER (ORDER BY v.total_vendido DESC) AS pos
    FROM ventas v
)
SELECT t.productName, t.total_vendido
FROM top10 t
JOIN total tg
WHERE t.pos <= 10
  AND (t.total_vendido / tg.total_global) >= 0.04
ORDER BY t.total_vendido DESC;