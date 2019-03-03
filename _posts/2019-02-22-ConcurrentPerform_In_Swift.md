---
layout: post
title: "Under the hood: DispatchQueue.concurrentPerform [Swift4]"
description: "What actually happen when you call DispatchQueue.concurrentPerform(iterations:execute:) in Swift."
tags: 
    - ConcurrentPerform
    - GCD
    - Grand Central Dispatch
    - Swift
    - iOS
    - multi-threading
---

### Version

- Swift 4.2
- iOS 12
- Xcode 10



## Problem

I am working on a Swift project recently. The App needs preload a lot of animations, which are grouped into 10-ish sets, before showing them. The legacy code was loading them in a serial manner, I try to do it concurrently instead.

I found some [great tutorials](https://www.raywenderlich.com/5371-grand-central-dispatch-tutorial-for-swift-4-part-2-2), where mentioned `DispatchQueue.concurrentPerform(iterations:execute:)` could do the trick.


## Experiments

Before changing the real project, I need a playground to try this method, and the questions below need to be answered.

* How many threads will be created?
* When will the method return?
* What is the difference of calling the method from between a Main and a Global queue.
* What will happen if switching to a Main queue in an iteration?
* What will happen if switching to a Global queue in an iteration?


### How many threads will be created?

```swift
class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        DispatchQueue.global(qos: .userInitiated).async {
            self.testConcurrence(threadCount: 20)
        }
    }

    private func testConcurrence(threadCount: Int) {
        print("testConcurrence thread=\(Thread.current)")
        let _ = DispatchQueue.global(qos: .userInitiated)
        DispatchQueue.concurrentPerform(iterations: threadCount, execute: { index in
            print("started index=\(index) thread=\(Thread.current)")
            // Download an image in a serial manner.
            let url = URL(string: "https://touren.me/2018/01/16/image_0.png")
            let _ = try? Data(contentsOf: url!)
            print("ended \(index)")
        })
        print("testConcurrence end thread=\(Thread.current)")
    }
}
```

Run the code in the emulator in my MacBook. For 20 iterations, up to 8 threads are scheduled, which makes sense. While multi-threading can occupy the CPUs fully, too many of them will create so much overhead that negates any gains from making the calls concurrently.
As we expected, all the tasks are dispatched concurrently.

* Detail Result:

```
testConcurrence thread=<NSThread: 0x600001b83140>{number = 1, name = main}
started index=1 thread=<NSThread: 0x600001682cc0>{number = 5, name = (null)}
started index=6 thread=<NSThread: 0x6000016972c0>{number = 8, name = (null)}
started index=4 thread=<NSThread: 0x600001696f80>{number = 6, name = (null)}
started index=3 thread=<NSThread: 0x6000016a66c0>{number = 4, name = (null)}
started index=2 thread=<NSThread: 0x6000016a6780>{number = 7, name = (null)}
started index=7 thread=<NSThread: 0x600001683540>{number = 9, name = (null)}
started index=5 thread=<NSThread: 0x600001b83140>{number = 1, name = main}
started index=0 thread=<NSThread: 0x6000016a6680>{number = 3, name = (null)}
ended 4
ended 5
ended 2
ended 3
started index=10 thread=<NSThread: 0x6000016a6780>{number = 7, name = (null)}
ended 7
ended 6
started index=12 thread=<NSThread: 0x600001683540>{number = 9, name = (null)}
started index=8 thread=<NSThread: 0x600001696f80>{number = 6, name = (null)}
ended 12
ended 0
ended 10
started index=15 thread=<NSThread: 0x6000016a6680>{number = 3, name = (null)}
ended 1
started index=13 thread=<NSThread: 0x6000016972c0>{number = 8, name = (null)}
started index=9 thread=<NSThread: 0x600001b83140>{number = 1, name = main}
ended 13
started index=14 thread=<NSThread: 0x600001683540>{number = 9, name = (null)}
started index=18 thread=<NSThread: 0x6000016972c0>{number = 8, name = (null)}
started index=11 thread=<NSThread: 0x6000016a66c0>{number = 4, name = (null)}
ended 15
started index=17 thread=<NSThread: 0x600001682cc0>{number = 5, name = (null)}
ended 8
ended 9
ended 18
ended 14
started index=16 thread=<NSThread: 0x6000016a6780>{number = 7, name = (null)}
ended 11
started index=19 thread=<NSThread: 0x6000016a6680>{number = 3, name = (null)}
ended 17
ended 16
ended 19
testConcurrence end thread=<NSThread: 0x600001b83140>{number = 1, name = main}
```

### When will the method return?

From the result above, the concurrentPerform method will return till all the iterations finished.
You can think of it as a `for` loop, where the following code will be executed after the loop is done, although the iterations are executed concurrently instead of serially.

**_Reminder:_**

Don't get confused by the example code, where I am using synchronous way to download an image.
Use an asynchrous way like [Apple official document](https://developer.apple.com/documentation/foundation/nsdata/1407864-init#discussion) suggested.



### What is the difference of calling the method from between a Main and a Global queue.

Let's change our method `viewDidLoad` a bit:

```swift
class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Run in the Main queue.
        self.testConcurrence(threadCount: 4)

        // Run in the Global queeu.
        DispatchQueue.global(qos: .userInitiated).async {
            self.testConcurrence(threadCount: 4)
        }
    }

    //...
}
```

From the result below, both queues will use the current thread to dispatch iterations, and the following code will be running in the same thread as well.

The subtle difference is the Global queue will **NOT** dispatch iterations to a Main queue.

* Detail Result:

```
testConcurrence thread=<NSThread: 0x6000010956c0>{number = 1, name = main}
started index=0 thread=<NSThread: 0x6000010956c0>{number = 1, name = main}
started index=1 thread=<NSThread: 0x6000010b2580>{number = 3, name = (null)}
started index=2 thread=<NSThread: 0x60000108e380>{number = 4, name = (null)}
started index=3 thread=<NSThread: 0x6000010b6cc0>{number = 5, name = (null)}
ended 0
ended 1
ended 2
ended 3

testConcurrence end thread=<NSThread: 0x6000010956c0>{number = 1, name = main}
testConcurrence thread=<NSThread: 0x6000010b6cc0>{number = 5, name = (null)}
started index=0 thread=<NSThread: 0x6000010b6cc0>{number = 5, name = (null)}
started index=1 thread=<NSThread: 0x6000010a1a40>{number = 6, name = (null)}
started index=3 thread=<NSThread: 0x6000010a1600>{number = 7, name = (null)}
started index=2 thread=<NSThread: 0x60000108e380>{number = 4, name = (null)}
ended 0
ended 3
ended 1
ended 2
testConcurrence end thread=<NSThread: 0x6000010b6cc0>{number = 5, name = (null)}
```

### What will happen if switching to a Main queue in iterations?

In the real project, it needs to update the UI after loading one group of animation. Let's change our method `testConcurrence` to simulate it:

```swift
class ViewController: UIViewController {
    // ...

    private func testConcurrence(threadCount: Int) {
        // ...    
            print("ended \(index)")

            // Simulate updating the UI.
            let currentThread = Thread.current
            DispatchQueue.main.async {
                print("main.async index=\(index), from thread=\(currentThread)")
            }
        // ...
    }
```

From the result below, if `DispatchQueue.concurrentPerform` is running in a Main queue, the updateing UI task within a iteration won't be started until method `testConcurrence` finished, Even worse is, according to [Apple's official document](https://developer.apple.com/documentation/dispatch#2527891)

> 
> Important
>
> Attempting to synchronously execute a work item on the main queue results in dead-lock.
> 

On the other side, running in a Global queue, it looks good, and the updating UI task is started as soon as possible.

* Detail Result:

```
testConcurrence thread=<NSThread: 0x600001c316c0>{number = 1, name = main}
started index=1 thread=<NSThread: 0x600001c15a40>{number = 3, name = (null)}
started index=2 thread=<NSThread: 0x600001c1c1c0>{number = 4, name = (null)}
started index=0 thread=<NSThread: 0x600001c316c0>{number = 1, name = main}
started index=3 thread=<NSThread: 0x600001c2f440>{number = 5, name = (null)}
ended 0
ended 3
ended 2
ended 1
testConcurrence end thread=<NSThread: 0x600001c316c0>{number = 1, name = main}
testConcurrence thread=<NSThread: 0x600001c188c0>{number = 6, name = (null)}
started index=0 thread=<NSThread: 0x600001c188c0>{number = 6, name = (null)}
started index=1 thread=<NSThread: 0x600001c04940>{number = 7, name = (null)}
started index=2 thread=<NSThread: 0x600001c1c1c0>{number = 4, name = (null)}
started index=3 thread=<NSThread: 0x600001c2f440>{number = 5, name = (null)}
main.async index=0, from thread=<NSThread: 0x600001c316c0>{number = 1, name = main}
main.async index=3, from thread=<NSThread: 0x600001c2f440>{number = 5, name = main}
main.async index=2, from thread=<NSThread: 0x600001c1c1c0>{number = 4, name = main}
main.async index=1, from thread=<NSThread: 0x600001c15a40>{number = 3, name = main}
ended 1
main.async index=1, from thread=<NSThread: 0x600001c04940>{number = 7, name = main}
ended 0
main.async index=0, from thread=<NSThread: 0x600001c188c0>{number = 6, name = main}
ended 2
main.async index=2, from thread=<NSThread: 0x600001c1c1c0>{number = 4, name = main}
ended 3
main.async index=3, from thread=<NSThread: 0x600001c2f440>{number = 5, name = main}
testConcurrence end thread=<NSThread: 0x600001c188c0>{number = 6, name = (null)}
```

### What will happen if switching to a Global queue in iterations?

Let's change the method `testConcurrence`, moving the image downloading code into a Global queue.
```swift
    private func testConcurrence(threadCount: Int) {
        print("testConcurrence thread=\(Thread.current)")
        let _ = DispatchQueue.global(qos: .userInitiated)
        DispatchQueue.concurrentPerform(iterations: threadCount, execute: { index in
            print("started index=\(index) thread=\(Thread.current)")
            let currentThread = Thread.current
            DispatchQueue.global().async {
                // Download an image in a serial manner.
                let url = URL(string: "https://touren.me/2018/01/16/image_0.png")
                let _ = try? Data(contentsOf: url!)
                print("global().async index=\(index), from thread=\(currentThread), thread=\(Thread.current)")
            }
            print("ended \(index)")
        })
        print("testConcurrence end thread=\(Thread.current)")
    }
```

From the reuslt below, `DispatchQueue.concurrentPerform` starts threads to schedule the iterations to other threads, sometimes the same one, and return. The download jobs are finished afterward. That said, you don't need to call it here at all. Basically it is the same as using a `for` loop to dispatch jobs to Global queues, which is more straighforward.

* Detail Result:

```
testConcurrence thread=<NSThread: 0x600001f13e00>{number = 3, name = (null)}
started index=0 thread=<NSThread: 0x600001f13e00>{number = 3, name = (null)}
started index=2 thread=<NSThread: 0x600001f149c0>{number = 4, name = (null)}
started index=1 thread=<NSThread: 0x600001f181c0>{number = 5, name = (null)}
ended 0
ended 1
started index=3 thread=<NSThread: 0x600001f29600>{number = 6, name = (null)}
ended 2
ended 3
testConcurrence end thread=<NSThread: 0x600001f13e00>{number = 3, name = (null)}
global().async, index=0, from thread=<NSThread: 0x600001f13e00>{number = 3, name = (null)}, thread=<NSThread: 0x600001f1d640>{number = 7, name = (null)}
global().async, index=2, from thread=<NSThread: 0x600001f149c0>{number = 4, name = (null)}, thread=<NSThread: 0x600001f1a700>{number = 8, name = (null)}
global().async, index=1, from thread=<NSThread: 0x600001f181c0>{number = 5, name = (null)}, thread=<NSThread: 0x600001f181c0>{number = 5, name = (null)}
global().async, index=3, from thread=<NSThread: 0x600001f29600>{number = 6, name = (null)}, thread=<NSThread: 0x600001f04a80>{number = 9, name = (null)}
```

## Back to the real world

After all these expirements, I decided to change our real project to use method `DispatchQueue.concurrentPerform`, and the result is pretty amazing, saving almost 50% loading time on my iPhone 6+, which has 2 CPU cores.


## Takeaways

For method `DispatchQueue.concurrentPerform`:

1. You can do any number of iterations, only up to 8 threads will be scheduled.
1. Always run it in a Global queue.
1. It is similar to `for` loop, iterates concurrently though.
1. Use it if you have some CPU intensive tasks need to be executed concurrently.
1. If you have a bunch of network tasks, there is no benefit for using it, which basically nobody knows, execpt you I hope. 😊😊😊


🎉🎉🎉 🙌 🙌 🙌 



------
