//////////////////////////////////////////////////////////////////////////////////////////////


//  PRACTICO 8  Modelado de Datos en MongoDB


//////////////////////////////////////////////////////////////////////////////////////////////



//  1.  Especificar en la colección users las siguientes reglas de validación: 
// El campo name (requerido) debe ser un string con un máximo de 30 caracteres, 
// email (requerido) debe ser un string que matchee con la expresión regular: "^(.*)@(.*)\\.(.{2,4})$" , 
// password (requerido) debe ser un string con al menos 50 caracteres.


db.runCommand(
    {
        collMod: "users",
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: ["name", "email", "password"],
                properties: {
                    name: {
                        bsonType: "string",
                        maxLength: 30,
                        description: "name must be a string and is required"
                    },
                    email: {
                        bsonType: "string",
                        pattern: "^(.*)@(.*)\\.(.{2,4})$",
                        description: "email must be a string and is required"
                    },
                    password: {
                        bsonType: "string",
                        minLength: 50,
                        description: "password must be a string, min length 50 and is required"
                    }
                }
            }
        },
        validationLevel: "moderate",
        validationAction: "error"
    }
)


// try {
//     db.users.insertOne(
//         { 
//             email: "jon@thewall.com", 
//             password: "I-dont-want-it-I-never-have-She-is-my-Queen-You-are-my-Queen" 
//         }
//     )
// }
// catch (e) {
//     print(e.message)
// }




//  2. Obtener metadata de la colección users que garantice que las reglas de validación fueron correctamente aplicadas.
db.getCollectionInfos({ name: "users" })




// 3. Especificar en la colección theaters las siguientes reglas de validación:
//  El campo theaterId (requerido) debe ser un int y 
// 
// location (requerido) debe ser un object con:
// --- un campo address (requerido) que sea un object con campos street1,
//       city, state y zipcode todos de tipo string y requeridos
// --- un campo geo (no requerido) que sea un object con un campo type, 
//      con valores posibles “Point” o null y coordinates que debe ser una lista de 2 doubles

// Por último, estas reglas de validación no deben prohibir la inserción 
// o actualización de documentos que no las cumplan sino que solamente deben advertir.

db.runCommand(
    {
        collMod: "theaters",
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: ["theaterId", "location"],
                properties: {
                    theaterId: {
                        bsonType: "int",
                        description: "theaterId must be an int and is required"
                    },
                    location: {
                        bsonType: "object",
                        required: ["address"],
                        properties: {
                            address: {
                                bsonType: "object",
                                required: ["street1", "city", "state", "zipcode"],
                                properties: {
                                    street1: {
                                        bsonType: "string",
                                        description: "street must be string and is required"
                                    },
                                    city: {
                                            bsonType: "string",
                                            description: "city must be string and is required"
                                    },
                                    state: {
                                        bsonType: "string",
                                        description: "state must be string and is required"
                                    },
                                    zipcode: {
                                        bsonType: "string",
                                        description: "zipcode must be string and is required"
                                    }
                                }
                            },
                            geo: {
                                bsonType: "object",
                                properties: {
                                    type: {
                                        enum: ["Point", null],
                                        description: "geo.type must be Point or null"
                                    },
                                    coordinates: {
                                        bsonType: "array",
                                        minItems: 2,
                                        maxItems: 2,
                                        items: {
                                            bsonType: "double"
                                        },
                                        description: "coordinates must be an array of 2 doubles"
                                    }
                                }
                            }
                        }
                    }

                }
            }
        },
        validationAction: "warn",
        validationLevel: "strict"
    }
)


// para comprobar: 
// VIOLACIÓN 1: Falta el campo requerido "theaterId"

let teatroInvalido2 = {
    location: {
        address: {
            street1: "123 Calle Falsa",
            state: "IL",
            zipcode: "60601"
        },
        geo: {
            type: "Point", 
            coordinates: [-87.62, 41.88]
        }
    }
}
// para ver el log ir a /var/log/mongodb/mongod.log
// buscar algo como "document failed validation" ...



// 4. Especificar en la colección movies las siguientes reglas de validación: 
// El campo 
//  - title (requerido) es de tipo string, 
//  - year (requerido) int con mínimo en 1900 y máximo en 3000, 
// y que tanto 
//  - cast, directors, countries, como genres 
// sean arrays de strings sin duplicados.

// Hint: Usar el constructor NumberInt() para especificar valores enteros a la hora de insertar documentos. 
// Recordar que mongo shell es un intérprete javascript y en javascript los literales numéricos son de tipo Number (double).

db.runCommand(
    {
        collMod: "movies",
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: ["title", "year"],
                properties: {
                    title: {
                        bsonType: "string",
                        description: "title must be a string and is required"
                    },
                    year: {
                        bsonType: "int",
                        minimum: 1900,
                        maximum: 3000,
                        description: "title must be a string and is required. Value between: [1800, 3000]"
                    },
                    cast: {
                        bsonType: "array",
                        uniqueItems: true,
                        items: {
                            bsonType: "string",
                            description: "cast must be an array of strings"
                        }
                    },
                    directors: {
                        bsonType: "array",
                        uniqueItems: true,
                        items: {
                            bsonType: "string",
                            description: "directors must be an array of strings"
                        }
                    },
                    countries: {
                        bsonType: "array",
                        uniqueItems: true,
                        items: {
                            bsonType: "string",
                            description: "countries must be an array of strings"
                        }
                    },
                    genres: {
                        bsonType: "array",
                        uniqueItems: true,
                        items: {
                            bsonType: "string",
                            description: "genres must be an array of strings"
                        }
                    }
                }
            }
        }
        validationAction: "error",
        validationLevel: "strict"
    }
)


// 5. Crear una colección userProfiles con las siguientes reglas de validación: 
// Tenga un campo 
//  - user_id (requerido) de tipo “objectId”, 
//  - language (requerido) con alguno de los siguientes valores [ “English”, “Spanish”, “Portuguese” ] 
//  - favorite_genres (no requerido) que sea un array de strings sin duplicados.

db.createCollection( "userProfiles",
    {
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: ["user_id", "language"],
                properties: {
                    user_id: {
                        bsonType: "objectId"
                    },
                    language: {
                        bsonType: "string",
                        enum: [ "English", "Spanish", "Portuguese" ]
                    },
                    favorite_genres: {
                        bsonType: "array",
                        uniqueItems: true,
                        items: {
                            bsonType: "string"
                        }
                    }
                }
            }
        },
        validationAction: "error",
        validationLevel: "strict"
    }
)



// 6. Identificar los distintos tipos de relaciones (One-To-One, One-To-Many) en las colecciones movies y comments.
//  Determinar si se usó documentos anidados o referencias en cada relación y justificar la razón.

// movies -> comments es One-To-Many. A un unico documento le corresponden uno o varios comentarios, y viceversa (comments -> movies es Many-to-One)

// Cada comment tiene campo unico "movie_id" que referencia a la pelicula. 
// En este caso, si se anidaran los comentarios dentro de un array para cada pelicula, el doc podria crecer muchisimo.
// Al usar referencias, las consultas son mas eficientes y flexibles.