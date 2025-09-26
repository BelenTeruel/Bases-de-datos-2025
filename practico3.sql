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


