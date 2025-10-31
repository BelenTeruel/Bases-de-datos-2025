//////////////////////////////////////////////////////////////////////////////////////////////


// -- PRACTICO 8 Pipeline de Agregación en MongoDB


//////////////////////////////////////////////////////////////////////////////////////////////



// -- 1. Cantidad de cines (theaters) por estado.

db.theaters.aggregate([
    {
        $group: {
            _id: "$location.address.state",
            cantidad_cines: { $sum: 1}
        }
    },
    { $sort: { cantidad_cines: -1 }}
]);


// 2. Cantidad de estados con al menos dos cines (theaters) registrados.
db.theaters.aggregate([
    {
        $group: {
            _id: "$location.address.state",
            cantidad_cines: { $sum: 1}
        }
    },
    { $match: { cantidad_cines: { $gte: 2 } } },
    { $count: "states_wal2_theaters" }
]);

// [ { states_wal2_theaters: 52 } ]



//  3. Cantidad de películas dirigidas por "Louis Lumière".
//  Se puede responder sin pipeline de agregación, realizar ambas queries.

db.movies.find({ directors: "Louis Lumière" }).count();
// 9

db.movies.aggregate([
  { $match: { directors: "Louis Lumière" } },
  { $count: "Louis_Lumière_movies" }
]);
// [ { Louis_Lumière_movies: 9 } ]



// 4. Cantidad de películas estrenadas en los años 50 (desde 1950 hasta 1959). 
// Se puede responder sin pipeline de agregación, realizar ambas queries.
db.movies.find({ year: { $gte: 1990, $lte: 1999 }}).count();

db.movies.aggregate([
    { $match: { year: { $gte: 1990, $lte: 1999 }}}, 
    { $count: "movies_50s" }
]);
// [ { movies_50s: 6080 } ]


//  5. Listar los 10 géneros con mayor cantidad de películas 
// (tener en cuenta que las películas pueden tener más de un género). 
// Devolver el género y la cantidad de películas. 
// Hint: unwind puede ser de utilidad

db.movies.aggregate([
    { $unwind: "$genres" },
    {   
        $group: {
            _id: "$genres",
            movies_count: { $sum: 1}
        }
    },
    { $sort: { movies_count: -1 }},
    { $limit: 10 },
    { $project: {
        _id: 0,
        genre: "$_id",
        movies_count: 1
    } }
]);



// 6. Top 10 de usuarios con mayor cantidad de comentarios, mostrando Nombre, Email y Cantidad de Comentarios.
db.comments.aggregate([
    {
        $group: {
            _id: { name: "$name", email: "$email" },
            comments_count: { $sum: 1}
        }
    },
    { $sort: { comments_count: -1 }},
    { $limit: 10 },
    {
        $project: {
            _id: 0,
            name: "$_id.name",
            email: "$_id.email",
            comments_count: 1
        }
    }
])


// 7. Ratings de IMDB promedio, mínimo y máximo por año de las películas estrenadas en los años 80 (desde 1980 hasta 1989), 
// ordenados de mayor a menor por promedio del año.

db.movies.aggregate([
    { $match: { year: { $gte: 1980, $lte: 1989 }} },
    { 
        $group: {
            _id: "$year",
            avg_rating: { $avg: "$imdb.rating" },
            min_rating: { $min: "$imdb.rating" },
            max_rating: { $max: "$imdb.rating" }
        } 
    },
    {  $sort : { avg_rating: -1 } },
    {
        $project: {
            _id: 0,
            year: "$_id",
            avg_rating: { $round: ["$avg_rating", 2] },
            min_rating: 1,
            max_rating: 1
        }
    }
])

// 8. Título, año y cantidad de comentarios de las 10 películas con más comentarios.
db.movies.aggregate([
    { 
        $lookup: {
            from: "comments",
            localField: "_id",
            foreignField: "movie_id",
            as: "comments"
        } 
    },
    {
        $project: {
            title: 1,
            year: 1,
            comments_count: { $size: "$comments"}
        }
    },
    { $sort: { comments_count: -1 }},
    { $limit: 10}
])


// 9.Crear una vista con los 5 géneros con mayor cantidad de comentarios, 
// junto con la cantidad de comentarios.
db.createView(
    "top_5_genres_wmost_comm",
    "movies",
    [
        {
            $lookup: {
                from: "comments",
                localField: "_id",
                foreignField: "movie_id",
                as: "comments"
            }
        },
        { $unwind: "$genres" },
        { 
            $group: {
                _id: "$genres",
                comments_count: { $sum: {$size: "$comments"}}
            }
        },
        { $sort: { comments_count: -1 }},
        { $limit: 5},
        { 
            $project: {
                _id: 0,
                genre: "$_id",
                comments_count: 1
            }    
        }
    ]
)


// mflix> db.top_5_genres_wmost_comm.find()
// [
//   { comments_count: 55021, genre: 'Comedy' },
//   { comments_count: 48918, genre: 'Drama' },
//   { comments_count: 39465, genre: 'Adventure' },
//   { comments_count: 38851, genre: 'Action' },
//   { comments_count: 21991, genre: 'Fantasy' }
// ]



// 10.Listar los actores (cast) que trabajaron en 2 o más películas dirigidas por "Jules Bass".
//  Devolver el nombre de estos actores junto con la lista de películas 
// (solo título y año) dirigidas por “Jules Bass” en las que trabajaron. 
// Hint1: addToSet
// Hint2: {'name.2': {$exists: true}} permite filtrar arrays con al menos 2 elementos, entender por qué.
// Hint3: Puede que tu solución no use Hint1 ni Hint2 e igualmente sea correcta


db.movies.aggregate([

    { $match: { directors: "Jules Bass" } },
    { $unwind: "$cast" },
    {
        $group: {
            _id: "$cast",
            movies: {
                $addToSet: { title: "$title", year: "$year" }
            }
        }
    },
    { $match: { "movies.1": {$exists: true } } },

    { $addFields: { movies_count: {$size: "$movies" } } },   // agrego solo para acomodar
    { 
        $project: {
            _id: 0,
            actor: "$_id",
            movies: 1,
            movies_count: 1
        }
    },
    { $sort: { movies_count: 1}}
])

//  11.Listar los usuarios que realizaron comentarios durante el mismo mes de 
// lanzamiento de la película comentada, mostrando Nombre, Email, 
// fecha del comentario, título de la película, fecha de lanzamiento.
//  HINT: usar $lookup con multiple condiciones 

db.movies.aggregate([
    {
        $lookup: {
            from: "comments",
            let: {
                movieId: "$_id",
                movieRelease: "$released"
            },
            pipeline: [
                { $match: { $expr: { $and: 
                    [
                        { $eq: [ "$movie_id", "$$movieId" ] },
                        { $eq: [ { $year: "$date" }, { $year: "$$movieRelease"} ] },
                        { $eq: [ { $month: "$date" }, { $month: "$$movieRelease"} ] },
                    ]
                    }}
                }
            ],
            as: "month_comments"
        }
    },
    { $unwind: "$month_comments" },
    {
        $project: {
            _id: 0,
            name: "$month_comments.name",
            email: "$month_comments.email",
            comment_date: "$month_comments.date",
            title: "$title",
            released: "$released"
        }
    }
])




// 12. Listar el id y nombre de los restaurantes junto con su puntuación máxima, mínima y la suma total. 
// Se puede asumir que el restaurant_id es único.

// a) Resolver con $group y accumulators.
db.restaurants.aggregate([
    { $unwind: "$grades" },
    {
        $group: {
            _id: {
                restaurant_id : "$restaurant_id",
                name: "$name"
            },
            min_score: { $min: "$grades.score" },
            max_score: { $max: "$grades.score" },
            sum_score: { $sum: "$grades.score" }
        }
    },
    {
        $project: {
            _id: 0,
            restaurant_id: "$_id.restaurant_id",
            name: "$_id.name",
            min_score: 1,
            max_score: 1,
            sum_score: 1
        }
    },
    { $sort: { name: 1 }}
])


// b) Resolver con expresiones sobre arreglos (por ejemplo, $sum) pero sin $group.
db.restaurants.aggregate([
    { $match: { "grades.0": { $exists: true } } },
    {
        $project: {
            _id: 0,
            name: 1,
            min_score: { $min: "$grades.score" },
            max_score: { $max: "$grades.score" },
            sum_score: { $sum: "$grades.score" }
        }
    },
    { $sort: { name: 1 }}
])



// c) Resolver como en el punto b) pero usar $reduce para calcular la puntuación total.
db.restaurants.aggregate([
    { $match: { "grades.0": { $exists: true } } },
    {
        $project: {
            _id: 0,
            name: 1,
            min_score: { $min: "$grades.score" },
            max_score: { $max: "$grades.score" },
            sum_score: { 
                $reduce: {
                    input: "$grades",
                    initialValue: 0,
                    in: { $add: [ "$$value", "$$this.score" ] }
                } 
            }
        }
    },
    { $sort: { name: 1 }}
])



// d) Resolver con find.


// Chat GPT soluciones

db.restaurants.find(
    {}, 
    { 
        restaurant_id: 1, 
        name: 1, 
        grades: 1, 
        _id: 0 
    }
).forEach(rest => {
    if (rest.grades && rest.grades.length > 0) {
        const scores = rest.grades.map(g => g.score);
        const min = Math.min(...scores);
        const max = Math.max(...scores);
        const sum = scores.reduce((a, b) => a + b, 0);
        printjson({
            restaurant_id: rest.restaurant_id,
            name: rest.name,
            min_score: min,
            max_score: max,
            sum_score: sum
        });
    }
});


db.restaurants.find(
    {}, 
    { 
        restaurant_id: 1, 
        name: 1, 
        grades: 1, 
        _id: 0 
    }
).forEach(
    ({ restaurant_id, name, grades }) => {
        if (!grades || !grades.length) return;
        const scores = grades.map(g => g.score);
         printjson({
            restaurant_id,
            name,
            min_score: Math.min(...scores),
            max_score: Math.max(...scores),
            sum_score: scores.reduce((a, b) => a + b)
        });
    }
);





// 13 Actualizar los datos de los restaurantes añadiendo dos campos nuevos. 

// "average_score": con la puntuación promedio
// "grade": con "A" si "average_score" está entre 0 y 13, 
//   con "B" si "average_score" está entre 14 y 27 
//   con "C" si "average_score" es mayor o igual a 28    

// Se debe actualizar con una sola query.
// HINT1. Se puede usar pipeline de agregación con la operación update
// HINT2. El operador $switch o $cond pueden ser de ayuda.


// con switch
db.restaurants.updateMany(
    {}, 
    [
        {
            $set: {
                avg_score: { $avg: "$grades.score" },
                grade: {
                    $switch: {
                        branches: [
                            { case: { $lte: ["$avg_score", 13] }, then: "A" },

                            { case: { $and: [ 
                                { $gte: ["$avg_Score", 14] }, 
                                { $lte: ["$avg_Score", 27] }
                            ] }, then: "B" },

                            { case: { $gte: ["$avg_score", 28] }, then: "C" }
                        ],
                        default: "Sin calificacion"
                    }
                }
            }
        }
    ]
)

// con cond
db.restaurants.updateMany(
    {},
    [
        {
            $set: {
                avg_score: { $avg: "$grades.score" },
                grade: {
                    $cond: {
                        if: { $lte: ["$avg_score", 13] },
                        then: "A",
                        else: {
                            $cond: {
                                if: { $lte: ["$avg_score", 27] },
                                then: "B",
                                else: "C"
                            }
                        }
                    }
                }
            }
        }
    ]
)


