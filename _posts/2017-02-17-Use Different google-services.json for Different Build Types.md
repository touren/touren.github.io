---
layout: post
title: Use Different google-services.json for Different Build Types
tags: 
    - android
---

Google had changed its configurations of services such as _Analytics_ to a single **google-service.json** file. Go to Google's developer console to generate the file and put on the app folder. Android Studio will pick it up and generate code for it. This is the tutorail of _[Google Analytics](https://developers.google.com/analytics/devguides/collection/android/v4/)_ that you can see how it works.

This is a nice way to set up configurations, but it causes a problem to us. We want to use different configurations for different enviornments like developemnt stage and production stage. So I have tried to accomplish this goal.

## Approaches
1. Hack the code to set different configurations. 
1. Use Gradle tasks to copy files in different build types or flavors..
1. Use source sets.

I used the approach 1 first. It works now, but I feel this way is unstable because once Google change the way it is. This approach might be broken. So I started searching other approaches. And finially I found approach 3 is the best way to do it.   

## Mechanism

Android Gradle has a useful mechanism to build different apps with mostly the same files. The mechanism is that put the code or files are different for different apps on related folders.

This is the sample tree of folders.
```text
/project
----/app
----/src : the root folder of source code
--------/main : the folder of source code for all the types(build types, flavors)
--------/test : the folder only for unit tests.
--------/androidTest : the folder only for android tests.

# above are defalut folders when you created a project, below are opitional.

--------/debug : the folder debug build type.
--------/release : the folder only for release build type.
--------/free : the folder only for free flavor.
--------/etc...
```

More info in [Configure Build Variants](https://developer.android.com/studio/build/build-variants.html)

When building, Gradle will take the file of current type and combine main folder. So I can put one google-services.json file under **/src/debug** folder, and another one put on **/src/main** folder for non-debug build(like the picture below), or more if we needs.

![the picture of the folders](/assets/images/2017-02-17-1.png)

Therefore, when the build type is debug, than the developemntal google-services.json is picked. On the other hand, when the build type is release, than the production google-services.json is picked.

So the goal is accomplished and **this approach doesn't add any code and can be done in a minture**.