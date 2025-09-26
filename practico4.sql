
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



