---
layout: post
title: "Use npm-link to share code locally"
description:  Use npm-link to share code to others projects locally
tags: 
    - npm
    - symlink
---

This article will show you how to use `npm link` to share code to others projects locally.

[Source code](https://github.com/wadehuang36/npm-sharedlib-example)

## Motivation
Sometime you want to extract code to become a shared library to make it reuseable. If you are nodejs developer, you probably want to make it as a node module, so you can use the same behavoir to load the library. However, you mightn't want to publish the library to public, you can use npm-link to publish the library locally.

what is npm-link, see https://docs.npmjs.com/cli/link

Basically, npm-link is create symlink the project, you want to share, in the npm folder, also the other project create other symlinks connect to that folder. So when you make a change, it affect other projects immediately(you don't need to use `npm update` to update)

## Example
In the repo, there are three projects. the sharedlib is the one want to share. And proejct1 and project2 want to use sharedlib.

First in the sharedlib folder, run

``` bash
~/Projects/shreadlib> npm link

# output
C:\Users\Wade\AppData\Roaming\npm\node_modules\sharedlib -> C:\Users\Wade\Projects\sharedlib
```
you can see npm create a symlink in its package folder.

Then in the project1 folder, run

``` bash
~\Projects\project1> npm link sharedlib

# output
C:\Users\Wade\Projects\project1\node_modules\sharedlib ->
C:\Users\Wade\AppData\Roaming\npm\node_modules\sharedlib -> 
C:\Users\Wade\Projects\sharedlib
```

Then in the project2 folder, run

``` bash
~\Projects\project2> npm link sharedlib

# output
C:\Users\Wade\Projects\project2\node_modules\sharedlib ->
C:\Users\Wade\AppData\Roaming\npm\node_modules\sharedlib -> 
C:\Users\Wade\Projects\sharedlib
```

you can see all `node_modules\sharedlib` are link to `~\Projects\sharedlib`. This is why changes affect other projects immediately, becasue they are pointer the same places in the hard disk.

# pros and cons
You can publish libraries locally and the libraries are updated instantly. Unlike public libraies, you have to push and pull the a server.
Also there is another benefit, you can simplify the path of require.

For example,
``` js
// because sharedlib is under the ./model_modules, so you don't need to use relative path.
var lib = require("sharedlib");
```

However, the linked packages aren't define in package.json. so other people want to start working on the project, they have to run npm-link manually at first. 

# npm-unlink
you can run `npm unlink` to remove the symlimks.