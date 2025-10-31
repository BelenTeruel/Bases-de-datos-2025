
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
// HINTS: 
//      (i) para actualizar se puede usar pipeline de agregación. 
//      (ii) El operador $cond o $switch pueden ser de utilidad.

db.grades.updateMany(
    { "class_id": 339 },
    [
        {
            $set: {
                avg_score: { $avg: "$scores.score" }
            }
        },
        {
            $set: {
                letter: {
                    $switch: {
                        branches: [
                            {   
                                case: {  $gte: ["$avg_score", 80] }, 
                                then: "P" 
                            },

                            { 
                                case: { $gte: ["$avg_score", 60] },  
                                then: "A" 
                            },
                        ],
                        default: "NA"
                    }
                }    
            }
        }
        
    ]
)



// 6. (a) Especificar reglas de validación en la colección grades para todos sus campos y
// subdocumentos anidados. Inferir los tipos y otras restricciones que considere
// adecuados para especificar las reglas a partir de los documentos de la colección.


db.runCommand({
    collMod: "grades",
    validator: {
        $jsonSchema: {
            bsonType: "object",
            required: ["_id", "student_id", "class_id"],
            properties: {
                _id: {   // redundante
                    bsonType: "objectId",
                },
                student_id: {
                    bsonType: "int",
                },
                scores: {
                    bsonType: "array",
                    items: {
                        bsonType: "object",
                        properties: {
                            type: {
                                bsonType: "string",
                            },
                            score: {
                                bsonType: "double",
                                minimum: 0.00,
                                maximum: 100.00
                            }
                        }
                    }
                },
                class_id: {
                    bsonType: "int"
                },
                avg_score: {
                    bsonType: "double"
                },
                letter: {
                    bsonType: "string",
                    enum: ["P", "A", "NA"]
                }
            }
        }
    },
    validationAction: "error",
    validationLevel: "strict"
})



// (b) Testear la regla de validación generando dos casos de fallas en la regla de
// validación y un caso de éxito en la regla de validación. Aclarar en la entrega cuales
// son los casos y por qué fallan y cuales cumplen la regla de validación. Los casos no
// deben ser triviales, es decir los ejemplos deben contener todos los campos..

// caso1 falla
db.grades.insertOne({
    student_id: 1001,
    class_id: 502,
    scores: [
        { type: "exam", score: 88.5 },  // falla porq score double
        { type: "homework", score: 92.3 }  //    ||
    ],
    avg_score: 90.25,
    letter: "p"   // p no esta en enum
});

// caso2 falla
db.grades.insertOne({
    student_id: ObjectId('56d5f7ec604eb380b0d8f332'),  // no es objectId
    class_id: 502,
    scores: [
        { type: "exam", score: 88.55 },  
        { type: "homework", score: 92.34 } 
    ],
    avg_score: 90.25,
    letter: "A"   
});


// caso que funciona
db.grades.insertOne({
    student_id: 1001, 
    class_id: 502,
    scores: [
        { type: "exam", score: 88.55 },  
        { type: "homework", score: 92.34 } 
    ],
    avg_score: 90.25,
    letter: "A"   
});


