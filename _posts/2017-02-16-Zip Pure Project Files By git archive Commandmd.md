---
layout: post
title: Zip Pure Project Files By "git archive" Command
tags: 
    - android
---

Sometimes we might need to send someone our project code. The simplest way is give them the link of the git repo, but sometimes it is a private repo and you don't want to give the permission to access. Or the homework you have to send your professor the zip of your project, not a link(maybe they don't know what git is). You cannot just select the project folder and zip it because there are so many IDEs generated files which are mass. It is very fussy to find them and delete all of them. So this post is talk you another easy way to accomplish this goal if your project use git( or other VCS like SVN).

On your project root folder or sub-folder(default git zips files under the current path), type

```
$ git archive -o=sourcecode.zip HEAD
```

* -o is --output, the name of the zip file
* HEAD is one of tree-ish which means the last commit of the current branch. It can be a branch, tag or hash, More info in [here](http://stackoverflow.com/questions/4044368/what-does-tree-ish-mean-in-git)

You can see there is a zip file on the current folder and the files in the zip are same as the last commit in the git. 

For full information, see http://git-scm.com/docs/git-archive