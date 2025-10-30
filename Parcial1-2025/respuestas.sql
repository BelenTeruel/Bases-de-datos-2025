
-- 1. .​ Listar los 5 clientes que más ingresos han generado a lo largo del tiempo.

SELECT 
    c.CustomerID AS customer_id,
    c.ContactName AS Nombre_contacto,
    SUM(od.Quantity * od.UnitPrice - od.Discount) AS Total_ingreso
FROM `Order Details` od
INNER JOIN Orders o ON o.OrderID = od.OrderID
INNER JOIN Customers c ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID 
ORDER BY Total_ingreso DESC;


-- 2.Listar cada producto con sus ventas totales, agrupados por categoría.

SELECT 
    c.CategoryName AS Categoria,
    p.ProductID AS Product_id,
    p.ProductName AS Nombre,
    SUM(od.Quantity) AS cantidad_producto_vendido 
FROM Products p
INNER JOIN `Order Details` od ON p.ProductID = od.ProductID
INNER JOIN Categories c ON c.CategoryID = p.CategoryID
GROUP BY c.CategoryName, p.ProductID
ORDER BY c.categoryID ASC;


-- 3. Calcular el total de ventas para cada categoría.
SELECT 
    c.CategoryID AS Categoria_ID,
    c.CategoryName AS Categoria,
    SUM(od.Quantity) AS ventas_totales 
FROM `Order Details` od
INNER JOIN Products p ON p.ProductID = od.ProductID
INNER JOIN Categories c ON c.CategoryID = p.CategoryID
GROUP BY p.CategoryID 
ORDER BY p.CategoryID ASC;


-- +--------------+----------------+----------------+
-- | Categoria_ID | Categoria      | ventas_totales |
-- +--------------+----------------+----------------+
-- | 1            | Beverages      | 9532           |
-- | 4            | Dairy Products | 9149           |
-- | 3            | Confections    | 7906           |
-- | 8            | Seafood        | 7681           |
-- | 2            | Condiments     | 5298           |
-- | 5            | Grains/Cereals | 4562           |
-- | 6            | Meat/Poultry   | 4199           |
-- | 7            | Produce        | 2990           |
-- +--------------+----------------+----------------+



-- 4. Crear una vista que liste los empleados con más ventas por cada año, mostrando
-- empleado, año y total de ventas. Ordenar el resultado por año ascendente.

CREATE VIEW sales_employee_per_year AS
SELECT 
    YEAR(o.OrderDate) AS Año, 
    CONCAT(e.FirstName, ' ', e.LastName) AS Nombre,
    SELECT MAX( SUM(od.Quantity)) AS cantidad_productos_vendidos

FROM `Order Details` od
INNER JOIN  Orders o ON o.OrderID = od.OrderID  
INNER JOIN Employees e ON e.EmployeeID = o.EmployeeID

GROUP BY  YEAR(o.OrderDate)
ORDER BY YEAR(o.OrderDate) ASC;


SELECT * FROM sales_employee_per_ye 


WITH ventas_por_empleado AS (
    SELECT 
        e.EmployeeID AS id_empleado,
        SUM(od.Quantity) as cantidad_ventas
    FROM `Order Details` od
    INNER JOIN  Orders o ON o.OrderID = od.OrderID  
    INNER JOIN Employees e ON e.EmployeeID = o.EmployeeID
    GROUP BY e.EmployeeID
)
SELECT
    YEAR(o.OrderDate) AS Año, 
    e.EmployeeID AS id_emp,
    MAX(vpe.cantidad_ventas) AS cantidad_productos_vendidos

FROM Orders o, ventas_por_empleado vpe
INNER JOIN Employees e ON e.EmployeeID = o.EmployeeID
WHERE e.EmployeeID = id_empleado

GROUP BY  YEAR(o.OrderDate), vpe.id_empleado
ORDER BY YEAR(o.OrderDate) ASC;


    CONCAT(e.FirstName, ' ', e.LastName) AS Nombre,






SELECT 
    YEAR(o.OrderDate) AS Año, 
    e.EmployeeID AS id_empleado,
    CONCAT(e.FirstName, ' ', e.LastName) AS Nombre,
    SUM(od.Quantity) AS cantidad_productos_vendidos
FROM `Order Details` od
INNER JOIN  Orders o ON o.OrderID = od.OrderID  
INNER JOIN Employees e ON e.EmployeeID = o.EmployeeID
GROUP BY  YEAR(o.OrderDate),e.EmployeeID 
ORDER BY YEAR(o.OrderDate) ASC;





WITH ventas_por_empleado AS (
    SELECT 
        YEAR(o.OrderDate) AS Año, 
        e.EmployeeID AS id_empleado,
        CONCAT(e.FirstName, ' ', e.LastName) AS Nombre,
        SUM(od.Quantity) AS cantidad_productos_vendidos
    FROM `Order Details` od
    INNER JOIN  Orders o ON o.OrderID = od.OrderID  
    INNER JOIN Employees e ON e.EmployeeID = o.EmployeeID
    GROUP BY YEAR(o.OrderDate),e.EmployeeID 
),
ventas_max AS (
    SELECT 
        Año,
        MAX(cantidad_productos_vendidos) AS prods_vendidos 
    FROM ventas_por_empleado
)
SELECT 
    vpe.Año,
    vpe.id_empleado,
    vpe.Nombre,
    vm.prods_vendidos 
FROM ventas_por_empleado vpe
JOIN ventas_max vm ON vpe.Año = vm.Año
ORDER BY vpe.Año ASC;




-- 5.rear un trigger que se ejecute después de insertar un nuevo registro en la tabla
-- Order Details. Este trigger debe 
    -- actualizar la tabla Products para disminuir la
-- cantidad en stock (UnitsInStock) del producto correspondiente, restando la
-- cantidad (Quantity) que se acaba de insertar en el detalle del pedido.

DELIMITER $$
CREATE TRIGGER Update_stock_after_sale 
AFTER INSERT ON `Order Details`
FOR EACH ROW
BEGIN 
    UPDATE Products
    SET UnitsInStock = UnitsInStock - NEW.Quantity
    WHERE ProductID = NEW.ProductID 
    AND UnitsInStock > 0 ;
END $$
DELIMITER ;



MySQL root@localhost:northwind> show columns from `Order Details`
+-----------+---------------+------+-----+---------+-------+
| Field     | Type          | Null | Key | Default | Extra |
+-----------+---------------+------+-----+---------+-------+
| OrderID   | int           | NO   | PRI | <null>  |       |
| ProductID | int           | NO   | PRI | <null>  |       |
| UnitPrice | decimal(10,4) | NO   |     | 0.0000  |       |
| Quantity  | smallint      | NO   |     | 1       |       |
| Discount  | double        | NO   |     | 0       |       |
+-----------+---------------+------+-----+---------+-------+
INSERT INTO `Order Details` Values (20248, 11, 14, 12, 0.0);





-- 6. Crear un rol llamado admin y otorgarle los siguientes permisos:
-- ●​ crear registros en la tabla Customers.
-- ●​ actualizar solamente la columna Phone de Customers.

CREATE ROLE adminT;
GRANT INSERT ON northwind.Customers TO adminT ;
GRANT UPDATE (Phone) ON northwind.Customers TO 'adminT';

