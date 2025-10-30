//////////////////////////////////////////////////////////////////////////////////////////////


//  PRACTICO 7 Operaciones CRUD


//////////////////////////////////////////////////////////////////////////////////////////////




// 1. Insertar 5 nuevos usuarios en la colección users. Para cada nuevo usuario creado, 
// insertar al menos un comentario realizado por el usuario en la colección comments.


db.users.insertMany(
    [
        {
            name: 'Rhaenyra Targaryen',
            email: 'milly_alcock@houseofthedragon.es',
            password: '$2b$12$WOnxubQc4RUzeIfSf0D2PO2YH1xaA30eZWk62SBuwEfMOqSna5aYy'
        },
        {
            name: 'Daemon Targaryen',
            email: 'matt_smith@houseofthedragon.es',
            password: '$2b$12$7RgjFPlwrzSeeCah8FH3fOCXpzuSGWLRHctzM6EhwniR3RS/EzWce'
        },
        {
            name: 'Alicent Hightower',
            email: 'olivia_cooke@houseofthedragon.es',
            password: '$2b$12$bLWvaIlLU/XXp/hIhNiqDeTo9uGZSEioTc7p9TbrMXISakpl0h7WO'
        },
        {
            name: 'Viserys I Targaryen',
            email: 'paddy_considine@houseofthedragon.es',
            password: '$2b$12$PcjW/vxUAK2C2/6FUKk0xuAmYDSs./roRkENsZ7ItYOhTQ.femlu2'
        },
        {
            name: 'Ser Criston Cole',
            email: 'fabien_frankel@houseofthedragon.es',
            password: '$2b$12$Ypdsy3pCnHnEKIQgMo0BaeMHyKqyZY.1Jgv7vWT4wx8LBjNDB7d4O'
        }
    ]
)

// db.users.find({ name: { $in: ["Ser Criston Cole", "Alicent Hightower"] } })



db.comments.insertMany([
    {
        name: 'Daemon Targaryen',
        email: 'matt_smith@houseofthedragon.es',
        movie_id: ObjectId('573a1393f29313caabcdd4c3'),
        text: 'Buena peli',
        date: new Date()
    },
    {
        name: 'Rhaenyra Targaryen',
        email: 'milly_alcock@houseofthedragon.es',
        movie_id: ObjectId('573a1393f29313caabcdc096'),
        text: 'Buena peli2',
        date: new Date()
    },
    {
        name: 'Ser Criston Cole',
        email: 'fabien_frankel@houseofthedragon.es',
        movie_id: ObjectId('573a1393f29313caabcdc096'),
        text: 'Malisima',
        date: new Date()
    },
    {
        name: 'Viserys I Targaryen',
        email: 'paddy_considine@houseofthedragon.es',
        movie_id: ObjectId('573a1392f29313caabcdb314'),
        text: 'Buena',
        date: new Date()
    },
    {
        name: 'Alicent Hightower',
        email: 'olivia_cooke@houseofthedragon.es',
        movie_id: ObjectId('573a1392f29313caabcdb314'),
        text: 'No me gusto',
        date: new Date()
    }
])



// 2. Listar el título, año, actores (cast), directores y rating de las 
// 10 películas con mayor rating (“imdb.rating”) de la década del 90. 
// ¿Cuál es el valor del rating de la película que tiene mayor rating? 
// (Hint: Chequear que el valor de “imdb.rating” sea de tipo “double”).


db.movies.find(
    { 
        year: { $gte: 1990, $lte: 1999 },
        "imdb.rating" : { $type: "double" }
    },
    {
        title: 1,
        year: 1,
        cast: 1, 
        directors: 1,
        "imdb.rating" : 1,
        _id: 0
    }
)
.sort ({"imdb.rating" : -1 })
.limit(10)



// 3. Listar el nombre, email, texto y fecha de los comentarios que la película con id (movie_id) 
// ObjectId("573a1399f29313caabcee886") recibió entre los años 2014 y 2016 inclusive. 
// Listar ordenados por fecha. Escribir una nueva consulta (modificando la anterior) 
// para responder ¿Cuántos comentarios recibió?


db.comments.find(
    {
        date: {
            $gte: ISODate("2014-01-01T00:00:00Z"),
            $lt: ISODate("2017-01-01T00:00:00Z")
        },
        movie_id: ObjectId("573a1399f29313caabcee886"),
    },
    {
        _id: 0,
        name: 1,
        email: 1,
        text: 1,
        date: 1
    }
)
.sort( { date: 1 })


// Listar el nombre, id de la película, texto y fecha de los 3 comentarios más recientes realizados por el usuario con email patricia_good@fakegmail.com. 

db.comments.find(
    {   
        email: 'patricia_good@fakegmail.com'
    },
    {
        _id: 0,
        name: 1,
        movie_id: 1,
        text: 1, 
        date: 1
    }
). sort( { date: -1 })
.limit (3)



// 5. Listar el título, idiomas (languages), géneros, fecha de lanzamiento (released) y número de votos (“imdb.votes”) 
// de las películas de géneros Drama y Action (la película puede tener otros géneros adicionales), 
// que solo están disponibles en un único idioma y por último tengan un rating (“imdb.rating”) mayor a 9 o bien
//  tengan una duración (runtime) de al menos 180 minutos. Listar ordenados por fecha de lanzamiento y número de votos.


db.movies.find(

    {
        genres: { $all: ["Drama", "Action"]},
        languages: { $exists: true, $size: 1 },
        $or : [ 
            { runtime: { $gte: 0.80} }, 
            { "imdb.rating": { $gte: 9 }}
        ]
    },
    {
        _id: 0,
        title: 1,
        genres: 1,
        languages: 1,
        year: 1,
        "imdb.votes": 1
    }
)
.sort({ released: 1, "imdb.votes": 1 })


// 6 Listar el id del teatro (theaterId), estado (“location.address.state”), ciudad (“location.address.city”), 
// y coordenadas (“location.geo.coordinates”) de los teatros que se encuentran en algunos de los 
// estados "CA", "NY", "TX" y el nombre de la ciudades comienza con una ‘F’. Listar ordenados por estado y ciudad.

db.theaters.find(

    {
        "location.address.state": { $in: ["CA", "NY", "TX"] },
        "location.address.city": { $regex: /^F/i }
    },
    {
        _id: 0,
        theaterId: 1,
        "location.address.state": 1,
        "location.address.city": 1,
        "location.geo.coordinates": 1
    }
)
.sort({"location.address.state": 1, "location.address.city": 1})


// 7. Actualizar los valores de los campos texto (text) y fecha (date) del comentario 
// cuyo id es ObjectId("5b72236520a3277c015b3b73") a "mi mejor comentario" y fecha actual respectivamente.

db.comments.updateOne( 
    { 
        _id: ObjectId("5b72236520a3277c015b3b73")
    }, 
    {
        $set: {
            text: 'mi mejor comentario',
            date: new Date()
        }
    }
)


// db.comments.findOne({ _id: ObjectId("5b72236520a3277c015b3b73") })



// 8 .Actualizar el valor de la contraseña del usuario cuyo email es joel.macdonel@fakegmail.com 
// a "some password". La misma consulta debe poder insertar un nuevo usuario en caso que el usuario no exista.
//  Ejecute la consulta dos veces. ¿Qué operación se realiza en cada caso?  (Hint: usar upserts). 


db.users.updateOne( 
    { email: 'joel.macdonel@fakegmail.com' }, 
    { $set: { password: 'some password' }},
    { upsert: true }
)


// 9. Remover todos los comentarios realizados por el usuario cuyo email es victor_patel@fakegmail.com durante el año 1980.

db.comments.deleteMany(

    {
        date: {
            $gte: ISODate("1980-01-01T00:00:00Z"),
            $lt: ISODate("1981-01-01T00:00:00Z")
        },
        email: 'victor_patel@fakegmail.com'
    }
)



// 10. Listar el id del restaurante (restaurant_id) y las calificaciones de los restaurantes donde al menos una 
// de sus calificaciones haya sido realizada entre 2014 y 2015 inclusive, 
// y que tenga una puntuación (score) mayor a 70 y menor o igual a 90.


db.restaurants.find(
    { 
        "grades.date": { 
            $gte: ISODate("2014-01-01T00:00:00Z"), 
            $lte: ISODate("2015-12-31T23:59:59Z") 
        },
        "grades.score": {$gt: 70, $lte: 90}
    },
    {
        _id: 0,
        restaurant_id: 1,
        grades: 1,
    }
)


// 11. Agregar dos nuevas calificaciones al restaurante cuyo id es "50018608". 
// A continuación se especifican las calificaciones a agregar en una sola consulta.  
// { "date" : ISODate("2019-10-10T00:00:00Z"), "grade" : "A","score" : 18 },
// { "date" : ISODate("2020-02-25T00:00:00Z"), "grade" : "A", "score" : 21 }

db.restaurants.updateOne(
    { restaurant_id: '50018608'},
    {
        $push: {
            grades: {
                $each: [
                    { "date" : ISODate("2019-10-10T00:00:00Z"), "grade" : "A","score" : 18 },
                    { "date" : ISODate("2020-02-25T00:00:00Z"), "grade" : "A", "score" : 21 }
                ]
            }
        }
    }
)

// db.restaurants.findOne( {restaurant_id : '50018608'})

