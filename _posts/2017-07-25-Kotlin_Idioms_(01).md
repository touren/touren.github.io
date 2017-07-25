---
layout: post
title: Kotlin Idioms (01)
description: Compare Kotlin and Java by solving the sample problem.
tags: 
    - Kotlin
    - Java
    - Kotlin Idiom
---

## Problem

Given a list of Strings ending as #nnnn, nnnn is a integer representing it's serial ID, find the next serial ID.
For example: 
    [] ==> 1
    [""] ==> 1
    ["Object#1", "Object#1"] ==> 2
    ["Object#1", "Object#5", "Object#3"] ==> 6

## Java Solution
```
    int maxId(List<String> list) {
        int maxID = 1;
        for (String str : list) {
            int sid = serialId(str);
            if (sid > maxID) maxID = sid;
        }
        return maxID;
    }
    int serialId(String str) {
        String[] strArray = str.split("#");
        if (strArray.length <2) return 0;
        try {
            return Integer.parseInt(strArray[1]);
        } catch (NumberFormatException e) {
            return 0;
        }
    }
```

## Kotlin Solution

```
    fun maxId(list: List<String>): Int {
        list.maxBy { it.seriralId() }?.let { it.seriralId().inc() } ?: 1
    }
    fun String.serialId(): Int = this.split("#").last().toIntOrNull() ?: 0
```

## Conclusion
It is obvious that the Kotlin solution is more simpler and neater than the Java one.
