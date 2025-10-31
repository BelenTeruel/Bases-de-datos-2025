
// 1. Escribir una consulta para calcular el promedio de puntuaciones de cada clase
// (class_id) y compararlo con el promedio general de todas las clases. 
// La consulta debe devolver un documento para cada clase que incluya el 
//  - class_id, 
//  - promedio de puntuaciones de esa clase 
//  - campo adicional que indique si el promedio de la clase está por encima 
//     o por debajo del promedio general de todas las clases. 

// Los resultados deben ordenarse de manera ascendente por class_id y de manera
// descendente por average_score.

// Estructura de cada documento del output:
// {
//     "class_id": <class_id>,
//     "average_score": <average_score>, // puntuación promedio de esta clase
//     "comparison_to_overall_average": "above" | "below" | "equal" // comparación con el
//     promedio general de todas las clases
// }


db.grades.aggregate([
    { $unwind: "$scores" },
    {
        $setWindowFields: {
            partitionBy: null,
            output: {
                general_avg: {
                    $avg: "$scores.score",
                    window: { documents: ["unbounded", "unbounded"] }
                }
            }
        }
    },
        // El resultado es que cada documento (después del $unwind)
        //  ahora tiene un campo general_avg con el promedio general de todas las puntuaciones.
    {
        $group: {
            _id: "$class_id",
            avg_score: { $avg: "$scores.score" },
            general_avg: { $first: "$general_avg" }  // lo paso a la siguiente etapa, es el mismo para todos los docs
        }
    },
    {
        $project: {
            _id: 0,
            class_id: "$_id",
            avg_score: "$avg_score",
            comparison_to_overall_average: {
                $cond: {
                    if: { $gt: ["$avg_score", "$general_avg"] },
                    then: "above",
                    else: {
                        $cond: {
                            if: { $lt: ["$avg_score", "$general_avg"]},
                            then: "below",
                            else: "equal"
                        }
                    }
                }
            }
        }
    },
    {
        $sort: {
            class_id: 1,
            avg_score: -1
        }
    }

])

// Otra opcion usando lookup con pipleine dentro
db.grades.aggregate([
    { $unwind: "$scores" },
    {
        $group: {
            _id: "$class_id",
            avg_score: { $avg: "$scores.score" }
        }
    },
    {
        $lookup: {
            from: "grades",
            pipeline: [
                { $unwind: "$scores" },
                {
                    $group: {
                        _id: null, // todos los docs
                        avg: { $avg: "$scores.score" }
                    }
                }
            ],
            as: "general_data"
        }
    },
    { $unwind: "$general_data" },
    {
        $project: {
            _id: 0,
            class_id: "$_id",
            avg_score: "$avg_score",
            comparison_to_overall_average: {
                $cond: {

                    if: { $gt: ["$avg_score", "$general_data.avg"] },
                    then: "above",
                    else: {
                        $cond: {

                            if: { $lt:  ["$avg_score", "$general_data.avg"]  },
                            then: "below",
                            else: "equal"
                        }
                    }
                }
                
            }
        }
    },
    {
        $sort: {
            class_id: 1,
            avg_score: -1
        }
    }
])


// Actualizar los documentos en la colección grades, ajustando todas las puntuaciones
// para que estén normalizadas entre 0 y 7
// La fórmula para la normalización es:

// Valor normalizado = (valor original / 100) * 7

// Por ejemplo:
// Si un estudiante sacó un 32 y otro sacó un 62, deberían ser actualizadas a:
// ● 2,24, porque (32/100)*7 = 2,24
// ● 4,34, porque (62/100)*7 = 4,34
// HINT: usar updateMany junto con map


db.grades.updateMany(
    {},
    [
        {
            $set: {   // voy a reescribir con un nuevo array
                scores: {
                    $map: { 
                        input: "$scores",   // array a iterar
                        as: "item",  // var name for each element
                        in: {       // expresion a aplicar a cada elem
                            $mergeObjects: [   // mergeObjects es para preservar los campos originales y solo sobreescribir score
                                "$$item",  // obj original
                                {
                                    score: {   // campo a sobrescribir
                                        $multiply: [
                                            { $divide: ["$$item.score",100] },
                                            7
                                        ]
                                    }
                                }
                            ]
                        }
                    }
                }
            }
        }
    ]
)
// Dentro de un pipeline de agregación (como el que se usa en updateMany), y especialmente dentro de operadores de array como $map:
//     $ (un solo signo): Se refiere a un campo del documento raíz que está siendo procesado (por ejemplo, $scores, $student_id).
//     $$ (doble signo): Se refiere a una variable definida dentro del pipeline. En tu caso, la variable item que definiste con as: "item".



// 3. Crear una vista "top10students_homework" que liste los 10 estudiantes con los
// mejores promedios para homework. Ordenar por average_homework_score
// descendiente.


db.createView(
    "top10students_homework",
    "grades",
    [   
        { $unwind: "$scores" },
        { $match: { "scores.type": "homework"}},
        {
            $group: {
                _id: "$student_id",
                avg_score: { $avg: "$scores.score" }
            }
        },
        { $limit: 10 },
        {
            $project: {
                _id: 0,
                student_id: "$_id",
                avg_score: "$avg_score"
            }
        },
        {
            $sort: { avg_score: 1 }
        }
    ]
)
// db.top10students_homework.find()



// 4. Especificar reglas de validación en la colección grades. El único requerimiento es
// que se valide que los type de los scores sólo puedan ser de estos tres tipos:
// [“exam”, “quiz”, “homework”]

db.runCommand(
    {
        collMod: "grades",
        validator: {
            $jsonSchema: {
                bsonType: "object",
                properties: {

                    scores: {
                        bsonType: "array",
                        items: {
                            bsonType: "object",
                            properties: {
                                type: {
                                    bsonType: "string",
                                    enum: ["exam", "quiz", "homework"]
                                }
                            }
                        }
                    }
                }
            }
        },
        validationLevel: "strict",
        validationAction: "error"
    }
)
// para chequear 

// db.grades.insertOne({
//     student_id: 9999,
//     class_id: 101,
//     scores: [
//         { type: "exam", score: 6.5 },      
//         { type: "quiz", score: 5.0 },      
//         { type: "final", score: 7.0 }      
//     ]
// });