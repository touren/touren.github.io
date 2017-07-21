---
layout: post
title: "Load Balance With Docker Swarm"
description: Scaling a webapp and load balancing on docker
tags: 
    - docker
---

In this article I will show you how to scale a webapp and load balancing on docker.

I have an example image [wadehuang36/load-balancing-example](https://hub.docker.com/r/wadehuang36/loadbalance-example/) on dockerhub and this is the [source code](https://github.com/wadehuang36/docker-practice/tree/master/Swarm-Example).

## Docker Swarm
Shortly, docker swarm mode is cluster mode. It also includes load balance natively, so once the webapp is deployed in a docker swarm. It has load balance without any settings. you can find more docker swarm infomation in [docker docs](https://docs.docker.com/engine/swarm/)

## Create Machines
In this example, I used docker-machine to create 1 leader and 3 workders, but you can use existing machines.
``` bash
docker-machine create -d hyperv swarm-leader
docker-machine create -d hyperv swarm-worker1
docker-machine create -d hyperv swarm-worker2
docker-machine create -d hyperv swarm-worker3
```

## Init Leader

docker swarm is master-slaver architecture, so I used the below command to make swarm-leader be the master.

`docker-machine ssh swarm-leader docker swarm init`

after the command, it printed out how to join the swarm like below.

``` text
Swarm initialized: current node (pe8j9blxkf79dn7ylspyxh0yu) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join \
    --token SWMTKN-1-0hzazb2a2ctcqi522wzh9gfknfpjz4o9aq7d1i11eblwg8pv8p-469qqo92lqe7o9x0h7r912av6 \
    192.168.1.164:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
```

## Join
Then made three workers join the swarm.

``` bash
docker-machine ssh swarm-worker1 docker swarm join --token SWMTKN-1-0hzazb2a2ctcqi522wzh9gfknfpjz4o9aq7d1i11eblwg8pv8p-469qqo92lqe7o9x0h7r912av6 192.168.1.164:2377
docker-machine ssh swarm-worker2 docker swarm join --token SWMTKN-1-0hzazb2a2ctcqi522wzh9gfknfpjz4o9aq7d1i11eblwg8pv8p-469qqo92lqe7o9x0h7r912av6 192.168.1.164:2377
docker-machine ssh swarm-worker3 docker swarm join --token SWMTKN-1-0hzazb2a2ctcqi522wzh9gfknfpjz4o9aq7d1i11eblwg8pv8p-469qqo92lqe7o9x0h7r912av6 192.168.1.164:2377
```

You can run `ssh swarm-leader docker node ls` to see how many node in the swarm like the below table.

|ID|HOSTNAME|STATUS|AVAILABILITY|MANAGER STATUS|
|--|--------|------|------------|--------------|
|vezme0sdqzh56gpfmshqnqsib *|swarm-leader|Ready|Active|Leader|
|pa2us0nqfeq7t038zu0sdou42|swarm-worker1|Ready|Active||
|1jichv8qxq3xhodd4zdvu1wf7|swarm-worker2|Ready|Active||
|xylw4du03apy3dkl1nfbyw2nc|swarm-worker3|Ready|Active||

## create docker-compose.yml
The verion 3 of docker-compose file supports `delpoy section`, so in this example I put 6 replicas.

``` yml
version: '3'
services:
  web:
    image: wadehuang36/loadbalance-example
    ports:
      - 80:3000
    deploy:
      replicas: 6
```

## delopy webapp via docker stack

``` bash
docker-machine env swarm-leader
# run the command it prints
docker stack deploy -c ./docker-compose.yml swarm_test

# the above command is equivalent to the below, but use docker stack is more convenient if you want to create more than one service.
# docker service create --replicas 6 wadehuang36/loadbalance-example swarm_test_web
```

you can 
RUN `docker stack ps swarm_test` and 
RUN `docker service ls` to see the status.

Visit http://<swarm-leader-ip>, http://<swarm-worker1-ip> and others, you can find the hostnames are different. (refreah might not change the hostname, becase the load balance policy which wants to let you visit the same node in a session.)

## Clean
``` bash
docker stack rm swarm_test
```