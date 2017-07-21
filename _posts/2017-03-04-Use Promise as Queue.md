---
layout: post
title: Use Promise as Queue
tags: 
    - javascript
    - promise
    - queue
---

Promise is very old concept which is older then me (I checked Wikipedia that Promise was proposed back to 1976). It is very good concept and has been implemented in many languages like Javascript, Java and C#. And after ECMAScript 2015, Promise is the build-in object of Javascript (before I used jQuery's implement). There are so many tutorials and articles about it. So instead of talking how to use Promise, I will try how to use Promise as Queue.

At first, I start few experiments to make sure, Promise can do as Queue to handle asynchronous function one after another.

### 1. the promise can take many then(). 
So we can make sure that one then() is for adding new Promise and one then() for the original caller.

### 2. Always trigger then() once it resolved. 
So we can make sure that the chain doesn't break.

```html
// Test 1
<button onclick="test1()">test 1</button>
<script>
    var p1 = new Promise(function (resolve, reject) {
        setTimeout(function() {
            console.log("p1 resolved");
            resolve("p1");
        }, 1000);
    });

    function test1() {
        console.log("start test1");
        p1.then(function(v) {
            console.log("test 1 finished by:" + v);
        });
    }

    test1();
    test1();
</script>

//Test 1 Output
start test1
start test1
P1 resolved
test 1 finished by p1
test 1 finished by p1

//hit test 1 button
start test1
test 1 finished by p1

//hit test 1 button
start test1
test 1 finished by p1
```

Every time **test 1** button is hit, the new **then()** will be triggered immediately. Promise make sure that all then() are called.  

### 3. The Error wouldn't break the chain.

```javascript
//Test 2
<script>
    var lastPromise = Promise.resolve(); // a dummy root;

    function promiseQueue(value) {
        var next = function() {
            return newPromise(value);
        };

        lastPromise = lastPromise.then(next, next); // go next either resolved or rejected  

        return lastPromise; //  new promise become lastPromise
    }

    function newPromise(value) {
        // use random setTimeout to simulate async function 
        return new Promise(function(resolve, reject) {
            setTimeout(function() {
                    if (value % 3 === 0) {
                        reject(value); // reject the promise
                    } else {
                        resolve(value); // reject the promise
                    }
                },
                Math.random() * 2000);
        });
    }

    for (var i = 0; i < 10; i++) {
        // change to newPromise(i) for Test3
        promiseQueue(i).then(function(v) {
            console.log(v, "finished");
        }).catch(function(v) {
            console.log(v, "falled");
        });
    }
</script>
```

**Test 2 with Queue Output**

![Test2](/assets/images/2017-03-04-1.gif)

**Test3 with no Queue Output**

![Test3](/assets/images/2017-03-04-2.gif)

You can see the result 3 has no order and run fast because it run concurrently.

## 4. It wouldn't block thread
```html
<button onclick="test4()">test 4</button>
<script>
    function test4() {
        // so although there are many Promise run, but the thread isn't blocked
        promiseQueue(Date.now()).then(function(v) {
            console.log(v, "finished");
        }).catch(function(v) {
            console.log(v, "falled");
        });
    }
</script>
```

## Why it is useful?
Promise.all also can make this example work, but Promise.all only use all the callers in one place and the same timing, so this idea works even if many callers call promiseQueue() in different places or different timing.
You can use this idea for something although it run asynchronously, but you want it also runs sequentially.    


## References
- [MDN - Promise](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise)
- [Wikipedia - Futures and promises](https://en.wikipedia.org/wiki/Futures_and_promises)