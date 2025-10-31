
// 1. Buscar los documentos donde el alumno tiene:

// (i) un puntaje mayor o igual a 80 en "exam" o bien un puntaje mayor o igual a 90 en
// "quiz" y
// (ii) un puntaje mayor o igual a 60 en todos los "homework" 
// (en otras palabras no tiene un puntaje menor a 60 en algún "homework")

// Las dos condiciones se tienen que cumplir juntas (es un AND)
// Se debe mostrar todos los campos excepto el _id, ordenados por el id de la clase y
// id del alumno en orden descendente y ascendente respectivamente.

db.grades.find(
    {
        $and: [
            { 
                $or: [
                    { "scores": { $elemMatch: { "type": "exam", "score": { $gte: 80 } } } },
                    { "scores": { $elemMatch: { "type": "quiz", "score": { $gte: 90 } } } }
                ]
            },
            {
                "scores": {
                    $not:  { $elemMatch: { "type": "homework", "score": { $lt: 60 } } } 
                }

            }
        ]
    },
    { _id: 0 } // oculto
).sort(
    { "class_id": -1, "student_id": 1 } 
)



// 2. Calcular el puntaje mínimo, promedio, y máximo que obtuvo el alumno en las clases
// 20, 220, 420. El resultado debe mostrar además el id de la clase y el id del alumno,
// ordenados por alumno y clase en orden ascendentes.


db.grades.aggregate([
    {   $match: { "class_id": { $in: [20, 220, 420] } } },
    {   $unwind: "$scores" },
    {
        $group: {
            _id: {
                student_id: "$student_id",
                class_id: "$class_id"
            },
            min_score: { $min: "$scores.score" },
            max_score: { $max: "$scores.score" },
            avg_score: { $avg: "$scores.score" }
        }
    },
    {   $sort: { "_id.student_id": 1, "_id.class_id": 1 } },
    {
        $project: {
            _id: 0,
            student_id: "$_id.student_id",
            class_id: "$_id.class_id",
            min_score: 1,
            max_score: 1,
            avg_score: 1
        }
    }
])




// 3. Para cada clase listar el puntaje máximo de las evaluaciones de tipo "exam" y el
// puntaje máximo de las evaluaciones de tipo "quiz". 
// Listar en orden ascendente por el id de la clase. 
// HINT: El operador $filter puede ser de utilidad.

db.grades.aggregate([
    {
        $group: {
            _id: "$class_id",
            max_exam: {
                $max: {
                    $map: {
                        input: {
                            $filter: {
                                input: "$scores",
                                cond: { $eq: [ "$$this.type", "exam" ] }
                            }
                        },
                        in: "$$this.score"
                    }
                }
            },
            max_quiz: {
                $max: {
                    $map: {
                        input: {
                            $filter: {
                                input: "$scores",
                                cond: { $eq: [ "$$this.type", "quiz" ] }
                            }
                        },
                        in: "$$this.score"
                    }
                }
            }
        }
    },
    {
        $project: {
            _id: 0,
            class_id: "$_id",
            max_exam: 1,
            max_quiz: 1
        }
    },
    {
        $sort: { class_id : 1 }
    }
])



// 4. Crear una vista "top10students" que liste los 10 estudiantes con los mejores promedios.
db.createView(
    "top10students",
    "grades",
    [
        {   $unwind: "$scores" },
        {
            $group: {
                _id: "$student_id",
                avg_score: { $avg: "$scores.score" }
            }
        },
        { $sort: { avg_score: -1 } },
        { $limit: 10 },
        {
            $project: {
                _id: 0,
                student_id: "$_id",
                avg_score: 1
            }
        }
    ]
)


// 5. Actualizar los documentos de la clase 339, agregando dos nuevos campos: 
// - "score_avg" que almacena el puntaje promedio 
// - "letter" que tiene
//      - valor "NA" si el puntaje promedio está entre [0, 60), 
//      - valor "A" si el puntaje promedio está entre [60, 80) 
//      - valor "P" si el puntaje promedio está entre [80, 100].
// HINTS: (i) para actualizar se puede usar pipeline de agregación. (ii) El operador
// $cond o $switch pueden ser de utilidad.


