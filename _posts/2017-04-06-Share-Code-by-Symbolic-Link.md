---
layout: post
title: "Share Code by Symbolic Link"
description: No need to copy code.
tags: 
    - git
    - symlink
---

[Symbolic Link](https://en.wikipedia.org/wiki/Symbolic_link) is soft link that OS treat the link of folder or file as original folder or file. So when you change the content of linked files or folders, the original files or folders get change too. Therefore, we can put the files we want to share, then different projects can access the same files. 

For example,
```text
/repo root
|--/shared # the original folder
|--/client
|----/src
|------/shared # the folder link to /shared
|--/server
|----/src
|------/shared # the folder link to /shared
```
we make shared folder share to client and server.

## What is the benefits?
you can just maintain one source. no matter which place your make a changes, all other places change, too. Before I use this method, I copied the files between client and server which is fussy and has potential problems if I forget to copy and paste to another place.

## Create link
creating link is a very easy command.

```bash
cd .\client\src

## for linux
ln -s ..\..\shared shared

## for windows
mklink /d shared ..\..\shared


cd .\server\src
## for linux
ln -s ..\..\shared shared

## for windows
mklink /d shared ..\..\shared
```

After you create the link, you can see the icon is different in file explorer and IDE.

![Folders](/assets/images/2017-04-06-1.png)


see [mklink](https://technet.microsoft.com/en-us/library/cc753194.aspx) document
see [ln](https://en.wikipedia.org/wiki/Ln_(Unix)) document

### Note:
1. you have to go to the path to create link because we need to create relative-based link.
2. mklink in windows needs administrator permission.


## Git Support
Because Symbolic Link is supported by OS, so if you copy the project folder to another place, the links will break, so you have to run above commands to create links again, but the good thing is. Git supports Symbolic Link. 

When you commit, Git treats a Symbolic Link as a file and the content is the path into the repo. 

![Github](/assets/images/2017-04-06-2.png)

When you clone a repo and checkout a branch. If your project has Symbolic Links, Git also create Symbolic Link for you, so you don't need to create by yourself.

In windows, you have to enable this feature when you install git for windows.

![Git for Windows](/assets/images/2017-04-06-3.png)

If you didn't enable the feature when installation. you can enable when you clone the repo.

```bash
## this command needs administrator permission ##
git clone -c core.symlinks=true <url>
```
Visit [this](https://github.com/git-for-windows/git/wiki/Symbolic-Links) for more info. 

## Issues
1. some watcher has problem to watch linked folder like `ng serve`, every time I make a change in shared folder, I have to re-run it.

2. if you clone the repo without administrator permission in windows, it is a little hard to make git re-create links for you.