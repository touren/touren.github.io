---
layout: post
title: Enable using debugger and step over in TypeScript and Node
tags: 
    - nodejs
    - typescript
---

TypeScript is a language created to overcome the disadvantages of JavaScript. Personally I think it succeeded on this goal. But it still cannot replace JavaScript yet because there is no TypeScript's interpreter. So we need to compile TypeScript to Javascript and used compiled Javascript in Node. So you cannot using step debugging directly. This is TypeScript's disadvantages. And this post is going to tell you how to eliminate this disadvantage.

### Init Project
Let us start with a brand new project to go through. There, we use koa for web framework.

``` bash
$ mkdir sample && cd sample
$ npm init  
$ tsc --init
$ npm install koa --save
$ npm install @types/koa --save-dev
$ mkdir src
```

### Add app.ts
make a simple ./src/app.ts looks like this.

``` js
import * as Koa from 'koa'

let app = new Koa();
app.use((ctx)=>{
    ctx.body = "hello world!";
});

app.listen(parseInt(process.env["PORT"]||3000));
```

### Add sourceMap:true in .tsconfig

.js.map file is the metadata of the compiled .js. So when you run the .js in Node debug mode. The IDE can match which the current stepped line is in correspondent .ts. The .tsconfig should looks like this.
``` js
{
    "compilerOptions": {
        "module": "commonjs",
        "target": "es5",
        "noImplicitAny": false,
        "sourceMap": true,
        "rootDir": "./src",
        "outDir": "./dist",
        "typeRoots": [
            "./node_modules/@types"
        ]
    }
}

```

Then run
```
$ tsc -p .
```
you can see ./dist/app.js and ./dist/app.map are generated.

### Launch node debug with ./dist/app.js
This picture is show how to add a debug configuration on WebStorm. And the step should be similar on other IDEs

![Settings](/assets/images/2017-03-14-1.png)

Select ./dist/app.js to run. Add a break point in app.ts and hit Debug button. you can use debugger with TypeScript source code. Step over, step into, see variables, stacks are exactly same as you do in JavaScript. 

![Settings](/assets/images/2017-03-14-2.png)

### Add Tasks to compile source before running debugger.

It is great, but the backward is every time before you run debugger, you have to compile the TypeScript source code. It's fussy, but some IDEs allow you add tasks before you launch Node's debugger.
we can add npm scripts and let IDEs to run these scripts. I thinks it is better.
``` js
  "scripts": {
    "build": "npm run clean && npm run tsc",
    "tsc": "tsc -p ./",
    "clean": "rm -rf dist"
  },
```

and add task. here use WebStorm as example.

![Settings](/assets/images/2017-03-14-3.png)

WebStorm also provides the build-in build TypeScript task, you can use it directly.

Other tips
1. You can use nodemon + ts_node to watch change. More info [see](https://basarat.gitbooks.io/typescript/docs/quick/nodejs.html)
2. Use different ports(like above sample. When debugging, set port=3100), so you don't need to stop nodemon before you launch debugger.