---
layout: post
title: JSON Schema
description: An introduction of JSON Schema
tags: 
    - json
---

JSON (JavaScript Object Notation) is a nice format. It isn't too freedom as plain text and complex as xml. The format is very readable for human. On the other hand, human can easily compose an JSON document without any specific tools. Therefore, it has become so popular. so many programming languages, platforms and database engines support JSON format and operations. However, its freedom causes some issues such as no tooling and hard to validate the JSON document. This is why [JSON Schema](http://json-schema.org/) came out. With the definition of JSON Schema, tools and libraries can understand the structure of your JSON document. Thus, they can helps you to compose your JSON document and verify it.

## Environments 
In this example, I used
- [Visual Studio Code](https://code.visualstudio.com/) to compose the JSON Schema and JSON Documents.
- [Nodejs](http://nodejs.org) for the API server.
- [ajv](https://www.npmjs.com/package/ajv) for the JSON validator.

## Compose the JSON Schema

This is an example schema of books.

``` js
// ./book-scheam.json
{
    "$schema": "http://json-schema.org/draft-06/schema",
    "title": "The Schema of Book",
    "type": "object",
    "required": [
        "title",
        "asin",
        "authors"
    ],
    "properties": {
        "title": {
            "type": "string"
        },
        "authors": {
            "type": "array",
            "items": {
                "$ref": "#/definitions/author"
            }
        },
        "categories": {
            "type": "array",
            "items": {
                "$ref": "#/definitions/category"
            }
        },
        "asin": {
            "type": "string"
        },
        "description": {
            "type": "string"
        }
    },
    "definitions": {
        "author": {
            "type": "object",
            "properties": {
                "name": {
                    "type": "string",
                    "minLength": 1
                },
                "bio": {
                    "type": "string"
                }
            },
            "additionalProperties": false
        },
        "category": {
            "type": "string",
            "enum": [
                "tech",
                "math",
                "sf",
                "kid"
            ]
        }
    }
}
```

The first property `$schema` tells tools which is the schema of this document. When I wrote this post, the latest schema is `http://json-schema.org/draft-06/schema`. 

There are 6 types **null**, **boolean**, **object**, **array**, **number** and **string**.

The root element is `object` type, so it can have `properties`, and some properties are `required`. 

`definitions` are the place to put sub-schemas. Use `$ref` to the location of the sub-schema like `"$ref": "#/definitions/category"`, `#` means the current document.

category is `enum`, so the value has to be one of them.

`additionalProperties` means the document accepts or rejects additional properties by default it is true.

For complete information, Visit [JSON Schema Document](http://json-schema.org/documentation.html)

## Tooling

There are many tools support JSON Schema, you can check your favorite tools support or not. Once the document has `$schema` on the root, tools will download the schema. The URI can relative(private) or absolute(public) path. You can put the schema on any online source, or publish to [JSON Schema Store](http://schemastore.org/json/). 

In this example, we just use relative path for demo purpose.

``` js
{
    "$schema": "./book-schema.json",
    "title": "Demo",
    "asin": "demo123",
    "authors": [
        {
            "name": "Wade"
        }
    ]
}
```

### Auto Complete Supports
![Auto Complete Supports](/assets/images/2017-07-03-json-schema-1.png)

### Validation Supports
![Validation Supports](/assets/images/2017-07-03-json-schema-2.png)

### Library Supports

In this example, I used ajv to validate the post data and response the validation result.

``` js
// for demo purpose, only use native nodejs function.
var http = require("http");
var ajv = require("ajv")();

var validate = ajv.compile(require('./book-schema.json'));

var server = http.createServer(function (req, res) {
    var chunks = [];
    req.on('data', chunk => chunks.push(chunk));
    req.on('end', () => {
        var data = JSON.parse(Buffer.concat(chunks).toString());

        var result = {
            isValid : validate(data),
            errors: validate.errors
        }

        res.setHeader("content-type", "application/json")
        res.write(JSON.stringify(result));
        res.end();
    })
});

server.listen(3000);
```

### A invalid result
![A invalid result](/assets/images/2017-07-03-json-schema-3.png)