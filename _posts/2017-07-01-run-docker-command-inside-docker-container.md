---
layout: post
title: Run Docker Commands inside Docker Containers
description: A tip for Windows (and maybe Mac) users to speed up docker commands or run linux-only commands
tags: 
    - docker
---

As you might know, Docker runs on Windows and Mac aren't quite naturally. On Windows or Mac, Docker client connect to Docker Daemon who dwells on a Linux VM on Hyper-V or VirtualBox. The communication is between Host Machine and Virtual Machine. This is unlike Docker on Linux which Docker client uses Unix domain socket to connect Docker Daemon. The communication is between two processes on the same machine. So when we run some Docker commands(like docker-export) which needs to transit mass data, the processing time on Linux is fast on Windows and Mac. Also, there are some commands are only linux exclusive (like [docker-squash](https://github.com/jwilder/docker-squash)). Furthermore, the Docker Linux VM cannot be operated directly like other VMs. Those things are a little troublesome when we use Docker on Windows or Mac, but fortunately, we can create a container and connect to the container. The communication are like this 

![CommunicationOfContainer](/assets/images/2017-07-01-docker-container-to-daemon.png)

So we run commands on the container, the communication is still within the same VM. And we can run Linux-Only commands, too.

## Initialization
First, we have to create a container that contains docker client. There are many to do it. In the below example, we use ubuntu image and just install docker client, so the image is very neat. Then create a new image called ubuntu:mine.

``` bash
# create a ubuntu temporary container
windows> docker run --name ubuntu -it -v /var/run/docker.sock:/var/run/docker.sock ubuntu
ubuntu> apt update && apt --yes install wget

# install docker client
ubuntu> wget -O /bin/docker https://master.dockerproject.org/linux/x86_64/docker
ubuntu> chmod 7 /bin/docker

# test 
ubuntu> docker ps # it should list running containers
ubuntu> exit

# create a new image called ubuntu:mine
windows> docker commit ubuntu ubuntu:mine

# remove temporary container
windows> docker rm ubuntu
```

### Note:
start with `windows>` means the commands are run on windows.<br/>
start with `ubuntu>` means the commands are run on ubuntu.


## Run ubuntu:mine
We can use below command to create the container based on the image we just created.

``` bash
windows> docker run --rm --name ubuntu --it -v /var/run/docker.sock:/var/run/docker.sock ubuntu:mine
```

### Create PowerShell Functions
If you use PowerShell, you can create a function, so you don't need to type all the words every time.
``` powershell
# write this function in
# C:\Users\your-name\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
function ubuntu() { 
    docker run -it --name ubuntu --rm -v /var/run/docker.sock:/var/run/docker.sock ubuntu:mine $args
}
```

### Note:
The argument `-v /var/run/docker.sock:/var/run/docker.sock` is the setting of Unix domain socket.

### Run commands in PowerShell
``` bash
# if no arguments, default is run /bin/bash
windows> ubuntu

# run specific commands by pass arguments
windows> ubuntu ls /bin 
```

## Scenario
In our team, we create a database image which is 6GB big for development and CI, so team members and test server can just pull the image and create a container. And to return initial state is just remove the container and create a new container. This saves a lot of works to set up the database environment. The problem is that every docker image is read only. When you changes a file, docker copies it into the new layer and change the file in the new layer, and the file in new layer overlaps the old file. So every time we use `docker commit` to create a new image. The size of the image is doubled (imagine a db file is 1GB. Even run a simple SQL to edit a row cause the file is copied to the new layer, so the new image just plus 1GB for a minus change). Therefore, we have to shrink the image before push to the docker register. we can use `docker export | docker import` to smash all layers into one, or other commands like  [docker-squash](https://github.com/jwilder/docker-squash).

The example uses `docker export | docker import` because we want to show the differences when run commands on Windows and Linux.

### Test 1: On Windows
``` bash
windows> docker export -o out.tar db-container
windows> docker import out.tar db-image
windows> del out.tar

# this two commands took 4 minutes, because transit out.tar took a lot time.
```

### Test 2 On Linux
``` bash
windows> ubuntu bash -c "docker export -o out.tar db-container && docker import test.tar db-image && rm out.tar"

# this two commands took 1.5 minutes
```

You can see there is a 2.5 minute difference. So this idea is useful for massive data operations of docker.