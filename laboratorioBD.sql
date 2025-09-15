------------------------------------------------------------------------------------------------------


-- PRACTICO 3 Joins y Conjuntos


------------------------------------------------------------------------------------------------------

-- 1. Lista el nombre de la ciudad, nombre del país, región y forma de gobierno 
-- de las 10 ciudades más pobladas del mundo.

SELECT country.Name, country.GovernmentForm, country.Region, city.Name, city.Population 
FROM city 
INNER JOIN country ON city.CountryCode = country.code 
ORDER BY city.Population DESC 
LIMIT 10;

----------------------------------------------------------------------------------------------------------------------------------

-- 2. Listar los 10 países con menor población del mundo,
-- junto a sus ciudades capitales (Hint: puede que uno de estos 
-- países no tenga ciudad capital asignada, en este caso deberá mostrar "NULL").
SELECT country.Name, city.Name, country.Population 
FROM country 
LEFT JOIN city ON country.Capital = city.Id 
ORDER BY country.Population ASC 
LIMIT 10;

----------------------------------------------------------------------------------------------------------------------------------

-- 3. Listar el nombre, continente y todos los lenguajes oficiales de cada país. 
-- (Hint: habrá más de una fila por país si tiene varios idiomas oficiales).
SELECT country.name, country.Continent, countrylanguage.Language 
FROM country 
INNER JOIN countrylanguage ON country.code = countrylanguage.CountryCode 
WHERE countrylanguage.IsOfficial = ‘T’;

----------------------------------------------------------------------------------------------------------------------------------


-- 4. Listar el nombre del país y nombre de capital, 
-- de los 20 países con mayor superficie del mundo.
SELECT country.Name, country.SurfaceArea, city.Name 
FROM country 
INNER JOIN city 
WHERE country.Capital = city.Id 
ORDER BY country.SurfaceArea DESC 
LIMIT 20;
----------------------------------------------------------------------------------------------------------------------------------

-- 5. Listar las ciudades junto a sus idiomas oficiales 
-- (ordenado por la población de la ciudad) y el porcentaje de hablantes del idioma.
SELECT city.Name, countrylanguage.language, countrylanguage.Percentage 
FROM city 
INNER JOIN countrylanguage ON city.CountryCode = countrylanguage.CountryCode 
WHERE countrylanguage.IsOfficial = 'T' 
ORDER BY city.Po pulation DESC

----------------------------------------------------------------------------------------------------------------------------------

-- 6. Listar los 10 países con mayor población y los 10 países con menor población 
-- (que tengan al menos 100 habitantes) en la misma consulta.
(
    SELECT country.Name, country.Population 
    FROM country
    WHERE country.Population >= 100 
    ORDER BY country.Population DESC 
    LIMIT 10
)
UNION ALL
(

    SELECT country.Name, country.Population 
    FROM country
    WHERE country.Population >= 100 
    ORDER BY country.Population ASC 
    LIMIT 10
)
ORDER BY Population DESC;

------------------------------------------------------------------------------------------------------

-- 7. Listar aquellos países cuyos lenguajes oficiales son el Inglés y el Francés 
-- (hint: no debería haber filas duplicadas).

SELECT DISTINCT c.Name AS País
FROM country c
WHERE EXISTS (
    SELECT 1 
    FROM countrylanguage cl1 
    WHERE cl1.CountryCode = c.Code 
    AND cl1.Language = 'English' 
    AND cl1.IsOfficial = 'T'
)
AND EXISTS (
    SELECT 1 
    FROM countrylanguage cl2 
    WHERE cl2.CountryCode = c.Code 
    AND cl2.Language = 'French' 
    AND cl2.IsOfficial = 'T'
)
ORDER BY c.Name;

------------------------------------------------------------------------------------------------------

-- 8. Listar aquellos países que tengan hablantes del Inglés pero no del Español en su población.

SELECT c.Name 
FROM country c 
INNER JOIN countrylanguage cl ON c.Code = cl.`CountryCode`
WHERE cl.Language = 'English'
EXCEPT 
SELECT c.Name
FROM country c 
INNER JOIN countrylanguage cl ON c.Code = cl.`CountryCode` 
WHERE cl.Language = 'Spanish';



------------------------------------------------------------------------------------------------------


-- PRACTICO 4 Consultas Anidadas y Agregaciones


------------------------------------------------------------------------------------------------------
-- 1. Listar el nombre de la ciudad y el nombre del país de todas las ciudades 
-- que pertenezcan a países con una población menor a 10000 habitantes.

SELECT 
    city.Name AS Ciudad, 
    country.Name AS Pais,
    country.Population
FROM city
INNER JOIN country on city.CountryCode = country.Code
WHERE country.Code IN (
    SELECT Code
    FROM country 
    WHERE country.Population < 10000
)
ORDER BY city.Name;

-- subconsulta: obtengo los codigos de los paises con poblacion < 100000.
-- luego hago inner join relacionando el codigo de cada ciudad del pais al que pertenece,
-- y los codigos de los paises devuelto por la subconsulta

-- resultado 
-- Adamston / Pitcairn  .....  West Island / Cocos 


----------------------------------------------------------------------------------------------------------------------------------

-- 2. Listar todas aquellas ciudades cuya población sea mayor
--  que la población promedio entre todas las ciudades.

WITH city_avg AS (
    SELECT avg(city.Population) AS avg_city_population
    from city
)
SELECT 
    city.Name AS Ciudad,
    city.Population AS poblacion
FROM city, city_avg
WHERE city.Population > city_avg.avg_city_population
ORDER BY city.Population DESC;
-- el with calcula el promedio de todas las ciudades y lo almaceno como avg_city_pop.. 
-- pero with es para tablas temporarias, es medio al vicio aca

-- esto esta mejor
SELECT 
    city.Name AS Ciudad,
    city.Population AS poblacion
FROM city
WHERE city.Population > (SELECT avg(city.Population) FROM city)
ORDER BY city.Population DESC;


-- resultado:
--  Mumbai (Bombay) /  10500000   .....  Tai´an / 350696 


----------------------------------------------------------------------------------------------------------------------------------

-- 3. Listar todas aquellas ciudades no asiáticas cuya población
--  sea igual o mayor a la población total de algún país de Asia.

SELECT 
    city.Name as Ciudad,
    city.Population AS poblacion,
    country.Name AS Pais
FROM city
INNER JOIN country ON city.CountryCode = country.Code 
WHERE country.Continent NOT IN ( 'Asia' )    -- WHERE country.Continent <> 'Asia'
AND city.Population >= SOME (
    SELECT country.Population 
    FROM country 
    WHERE country.Continent = 'Asia'
)
ORDER BY city.Population DESC;


-- resultado:   Sao Paulo  9968485 ... .  Kigali   286mil
-- de todas formas el resultado varia por el SOME, que toma la poblacion de algun pais de asia


----------------------------------------------------------------------------------------------------------------------------------
-- 4. Listar aquellos paises junto a sus idiomas no oficiales, que superen en porcentaje
-- de hablantes a cada uno de los idiomas oficiales del pais. 


SELECT 
    country.Name AS Pais,
    countrylanguage.Language AS lenguaje,
    countrylanguage.Percentage AS porcentaje
FROM country 
INNER JOIN countrylanguage ON country.Code = countrylanguage.CountryCode 
WHERE countrylanguage.IsOfficial = 'F' 
AND countrylanguage.Percentage >  ALL (
    SELECT countrylanguage.Percentage 
    FROM countrylanguage 
    WHERE country.Code = countrylanguage.CountryCode 
    AND countrylanguage.IsOfficial = 'T'
)
ORDER BY countrylanguage.Percentage DESC;

-- resultado: 
-- Cape Verde /  crioulo  100
-- ... 
-- wallis and futuna  / wallis   0


----------------------------------------------------------------------------------------------------------------------------------

-- 5. Listar (sin duplicados) aquellas regiones que tengan paises con una superficie menor a 1000 km2 
-- y exista (en el pais) al menos una ciudad con mas de 100mil habitantes 
-- (Hint: Esto puede resolverse con o sin una subquery, intenten encontrar ambas respuestas.)

-- subquery
SELECT DISTINCT   -- saca duplicados
    country.Region AS Region,
    country.SurfaceArea
FROM country
WHERE country.SurfaceArea < 1000 
AND country.Code IN (
    SELECT DISTINCT city.CountryCode 
    FROM city 
    WHERE city.Population > 100000
);

-- sin subquery
SELECT DISTINCT country.Region 
FROM country 
INNER JOIN city ON city.CountryCode = country.Code 
WHERE country.SurfaceArea < 1000 
AND city.Population > 100000;


-- resultado: 

-- +----------------+
-- | Region         |
-- +----------------+
-- | Middle East    |
-- | Eastern Asia   |
-- | Southeast Asia |
-- +----------------+

----------------------------------------------------------------------------------------------------------------------------------

-- 6. Listar el nombre de cada pais con la cantidad de habitantes de su ciudad mas poblada 
-- (hint: hay dos maneras de llegar al mismo resultado. Usando consultas escalares o usando agrupaciones, encontrar ambas)

-- Opcion 1:
SELECT 
    country.Name AS Pais,
    (
        SELECT max(city.Population)
        FROM city city
        WHERE city.CountryCode = country.Code 
    ) AS CiudadMasPoblada

FROM country
WHERE EXISTS (
    SELECT 1
    FROM city
    WHERE city.CountryCode = country.Code
)
ORDER BY CiudadMasPoblada DESC

----------------------------------------------------------------------------------------------------------------------------------

-- Opcion 2:
SELECT 
    country.Name AS Pais,
    max(city.Population) AS CiudadMasPoblada
FROM country  
INNER JOIN city ON city.CountryCode = country.Code 
GROUP BY country.Code, country.Name
ORDER BY CiudadMasPoblada DESC

-- resultado: India | 10500000  .....   Pitcairn / 42     


----------------------------------------------------------------------------------------------------------------------------------

-- 7. Listar aquellos países y sus lenguajes no oficiales cuyo porcentaje 
-- de hablantes sea mayor al promedio de hablantes de los lenguajes oficiales.

WITH avg_official AS (
    SELECT avg(countrylanguage.Percentage) AS avg_oficial_percentage
    FROM countrylanguage 
    WHERE countrylanguage.IsOfficial = 'T'
)
SELECT 
    country.Name AS Pais,
    countrylanguage.Language AS Lenguaje,
    countrylanguage.Percentage AS Porcentaje
FROM country
INNER JOIN countrylanguage ON countrylanguage.CountryCode = country.Code
CROSS JOIN avg_official
WHERE countrylanguage.Percentage > avg_oficial_percentage
AND countrylanguage.IsOfficial = 'F'
ORDER BY countrylanguage.Percentage DESC


-- resultado:   
-- Saint Kitts and Nevis  | Creole English   | 100   
-- ...
--  Samoa      | Samoan-English       | 52     

----------------------------------------------------------------------------------------------------------------------------------

-- 8. Listar la cantidad de habitantes por continente ordenado en forma descendente.
SELECT 
    country.Continent AS Continente,
    sum(country.Population) AS Poblacion
FROM country 
GROUP BY country.Continent
ORDER BY Poblacion DESC

-- resultado: | Asia          | 3705025700 |  ...  Antarctica  / 0


-- 9. Listar el promedio de esperanza de vida (LifeExpectancy) por continente 
-- con una esperanza de vida entre 40 y 70 años.

SELECT 
    country.Continent AS Continente,
    avg(country.LifeExpectancy) AS Esperanza_de_vida
FROM country 
GROUP BY country.Continent 
HAVING avg(country.LifeExpectancy) BETWEEN 40 AND 70
ORDER BY Esperanza_de_vida DESC

-- Resultado:
-- | Oceania    | 69.71500053405762 |
-- | Asia       | 67.44117676978017 |
-- | Africa     | 52.57192966394257 |


-- 10. Listar la cantidad máxima, mínima, promedio y suma de habitantes por continente.

SELECT 
    country.Continent AS Continente,
    max(country.Population) AS max_country_pop,
    min(country.Population) AS min_country_pop,
    avg(country.Population) AS avg_countries_pop,
    sum(country.Population) AS sum_contruies_pop
FROM country 
GROUP BY country.Continent
ORDER BY country.Continent ASC




-- Estas dos consultas son equivalentes:
SELECT * FROM table WHERE col = SOME (SELECT ...);    -- Igual a ALGUNO
SELECT * FROM table WHERE col IN (SELECT ...);

SELECT * FROM table WHERE col <> SOME (SELECT ...);  -- Al menos uno diferente

-- Estas dos consultas son equivalentes:
SELECT * FROM table WHERE col <> ALL (SELECT ...);    -- Distinto a todos
SELECT * FROM table WHERE col NOT IN (SELECT ...);
SELECT * FROM table WHERE col = ALL (SELECT ...);  -- Igual a TODOS
