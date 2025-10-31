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



// 7. Modelado 
//  Queries
//  1 - Listar el id, titulo, y precio de los libros y sus categorías de un autor en particular 
//  2 - Cantidad de libros por categorías
//  3 - Listar el nombre y dirección entrega y el monto total (quantity * price) 
//      de sus pedidos para un order_id dado.


// Debe crear el modelo de datos en mongodb aplicando las estrategias 
// “Modelo de datos anidados” y Referencias. 
// El modelo de datos debe permitir responder las queries de manera eficiente.
// Inserte algunos documentos para las colecciones del modelo de datos.
//  Opcionalmente puede especificar una regla de validación de esquemas para las colecciones. 



// 4 colecciones: orders, books, authors, categories

// collection book
{
    id: ObjectId("book0123456789"),
    title: "titulo",
    author: {
        author_id:ObjectId("author0123456789"),
        name: "Auth1"
    },
    price: 10.00,
    
    categories: [
        { _id: ObjectId("cat00", name: "Cat0") },
        { _id: ObjectId("cat01", name: "Cat1") }
    ]
}



// query1: 
 db.book.find(
    { author.name: "Auth1" },
    { _id: 0, title: 1, price: 1, categories: 1 }
)

// query 2
db.book.aggregate(
    { $unwind: "$categories" },
    {
        $group: {
            _id: "$categories.name"
            count: { $sum: 1 }
        }
    }
)


//  3 - Listar el nombre y dirección entrega y el monto total (quantity * price) 
//      de sus pedidos para un order_id dado.


//  Estructura de orders:
{
    _id: ObjectId("order123"),
    
    delivery_name: "Del Nombre",
    delivery_address: "Del Address",
    
    cc_name: "ccName",
    cc_number: "cc_num",
    cc_expiry: "cc_exp",
    
    items: [
        {
            book_id: ObjectId("book123"),
            quantity: 2,
            price: 15.50,
            title: "MongoDB Handbook"
        },
        {
            book_id: ObjectId("book456"),
            quantity: 1,
            price: 25.00,
            title: "JavaScript Guide"
        }
    ]
}


// Creacion de coleccion 'orders'

db.createCollection(
    "orders",
    {
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: [ "_id", "delivey_name", "delivery_address", "items" ],
                properties: {
                    _id: {
                        bsonType: "objectId"
                    },
                    delivery_name: {
                        bsonType: "string"
                    },
                    delivery_address: {
                        bsonType: "string"
                    },
                    cc_name: {
                        bsonType: "string"
                    },
                    cc_number: {
                        bsonType: "int"
                    },
                    cc_expiry: {
                        bsonType: "date"
                    },
                    items: {
                        bsonType: "array",
                        required: ["book_id", "quantity", "price", "title"],
                        properties: {
                            book_id: {
                                bsonType: "objectId"
                            },
                            quantity: {
                                bsonType: "int"
                            },
                            price: {
                                bsonType: "double"
                            },
                            title: {
                                bsonType: "string"
                            }
                        }
                    }
                }
            }
        },
        validationAction: "error",
        validationLevel: "strict"
    }
)



// /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////




// SOLUCIÓN 1: Con aggregate (más flexible y potente)
// ====================================================
db.orders.aggregate([
    // Paso 1: Filtrar por order_id
    { $match: { _id: ObjectId("order123") } },
    
    // Paso 2: Calcular el monto total
    {
        $project: {
            _id: 0,
            delivery_name: 1,
            delivery_address: 1,
            // Calcular total usando $reduce para sumar quantity * price de cada item
            total_amount: {
                $reduce: {
                    input: "$items",
                    initialValue: 0,
                    in: { 
                        $add: [
                            "$$value", 
                            { $multiply: ["$$this.quantity", "$$this.price"] }
                        ] 
                    }
                }
            },
            // Opcional: mostrar también los items con su subtotal
            items: {
                $map: {
                    input: "$items",
                    as: "item",
                    in: {
                        title: "$$item.title",
                        quantity: "$$item.quantity",
                        price: "$$item.price",
                        subtotal: { $multiply: ["$$item.quantity", "$$item.price"] }
                    }
                }
            }
        }
    }
])

// Resultado esperado:
// [
//   {
//     delivery_name: "Del Nombre",
//     delivery_address: "Del Address",
//     total_amount: 56.00,  // (2 * 15.50) + (1 * 25.00) = 31.00 + 25.00
//     items: [
//       { title: "MongoDB Handbook", quantity: 2, price: 15.50, subtotal: 31.00 },
//       { title: "JavaScript Guide", quantity: 1, price: 25.00, subtotal: 25.00 }
//     ]
//   }
// ]


// SOLUCIÓN 2: Versión simplificada con $sum (más directo)
// ========================================================
db.orders.aggregate([
    { $match: { _id: ObjectId("order123") } },
    {
        $project: {
            _id: 0,
            delivery_name: 1,
            delivery_address: 1,
            total_amount: {
                $sum: {
                    $map: {
                        input: "$items",
                        in: { $multiply: ["$$this.quantity", "$$this.price"] }
                    }
                }
            }
        }
    }
])


// EXPLICACIÓN DETALLADA:
// ======================

/*
¿Cómo funciona $reduce?
-----------------------
$reduce itera sobre un array y acumula un valor:

1. input: "$items" → el array de items a procesar
2. initialValue: 0 → empieza sumando desde 0
3. in: { $add: [...] } → en cada iteración:
   - $$value = valor acumulado hasta ahora
   - $$this = item actual del array
   - Calcula: $$value + (quantity * price)

Ejemplo paso a paso:
Item 1: 0 + (2 * 15.50) = 31.00
Item 2: 31.00 + (1 * 25.00) = 56.00
Resultado final: 56.00


¿Cómo funciona $map + $sum?
----------------------------
$map transforma cada elemento del array:
1. input: "$items" → array a transformar
2. in: { $multiply: [...] } → para cada item, calcula quantity * price
   Resultado: [31.00, 25.00]

$sum suma todos los valores del array resultante:
   $sum([31.00, 25.00]) = 56.00


Variables especiales:
---------------------
$$value  → valor acumulado en $reduce
$$this   → elemento actual del array que se está procesando
$        → referencia a campos del documento actual (ej: "$items", "$price")
*/


// SOLUCIÓN 3: Si prefieres calcular en la aplicación (no recomendado pero posible)
// =================================================================================
db.orders.find(
    { _id: ObjectId("order123") },
    { 
        delivery_name: 1,
        delivery_address: 1,
        items: 1,
        _id: 0
    }
).forEach(order => {
    const total = order.items.reduce((sum, item) => {
        return sum + (item.quantity * item.price);
    }, 0);
    
    printjson({
        delivery_name: order.delivery_name,
        delivery_address: order.delivery_address,
        total_amount: total
    });
})


// INSERTAR DOCUMENTOS DE EJEMPLO:
// ================================
db.orders.insertOne({
    _id: ObjectId("673a1234567890abcdef0001"),
    delivery_name: "Juan Pérez",
    delivery_address: "Av. Siempre Viva 742, Springfield",
    cc_name: "Juan Perez",
    cc_number: "1234-5678-9012-3456",
    cc_expiry: "12/2025",
    items: [
        {
            book_id: ObjectId("673b1111111111111111111a"),
            quantity: 2,
            price: 15.50,
            title: "MongoDB Handbook"
        },
        {
            book_id: ObjectId("673b1111111111111111111b"),
            quantity: 1,
            price: 25.00,
            title: "JavaScript Guide"
        },
        {
            book_id: ObjectId("673b1111111111111111111c"),
            quantity: 3,
            price: 10.00,
            title: "CSS Basics"
        }
    ]
})

// Probar la query:
db.orders.aggregate([
    { $match: { _id: ObjectId("673a1234567890abcdef0001") } },
    {
        $project: {
            _id: 0,
            delivery_name: 1,
            delivery_address: 1,
            total_amount: {
                $reduce: {
                    input: "$items",
                    initialValue: 0,
                    in: { $add: ["$$value", { $multiply: ["$$this.quantity", "$$this.price"] }] }
                }
            }
        }
    }
])
// Resultado: total_amount = 86.00  (31.00 + 25.00 + 30.00)