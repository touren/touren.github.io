---
layout: post
title: "Load Balance With Docker Compose"
description: Scaling a webapp and load balancing on docker compose
tags: 
    - docker
---


In this article I will show you a easy way to scale webapp containers and load balancing on docker.

I have an example image [wadehuang36/load-balancing-example](https://hub.docker.com/r/wadehuang36/loadbalance-example/) on dockerhub and this is the [source code](https://github.com/wadehuang36/docker-practice/tree/master/Load-Balance-Example).

## Dockerize your application.
In order to utilize docker, your application have to become a docker image.
You can see [the docker tutorial](https://docs.docker.com/engine/reference/builder/) to know how to use docker build and dockerfile. Also, you can see [my example](https://github.com/wadehuang36/docker-practice/tree/master/Load-Balance-Example) for reference. The example is a simple nodejs app, the following block are the code:

### app.js
``` js
var os = require('os');
var http = require('http');

var server = http.createServer(function (request, response) {
  console.log("hit from", request.connection.remoteAddress)
  response.writeHead(200, {"Content-Type": "application/json"});
  response.end(JSON.stringify({
      ip:request.connection.remoteAddress,
      env:process.env,
      net:os.networkInterfaces()
  }));
});

server.listen(3000);

console.log("Server running at http://127.0.0.1:3000/");
```

### Dockerfile
``` bash
FROM node:7-slim
MAINTAINER wadehuang36

EXPOSE 3000

WORKDIR /app

ADD app.js /app/app.js

ENTRYPOINT ["node"]
CMD ["app.js"] 
```

### docker-compose.yml
```yml
version: '2'
services:
  web:
    image: wadehuang36/loadbalance-example
    build: .
    ports:
      - 3000
  lb:
    image: dockercloud/haproxy
    ports:
      - 80:80
    links:
      - web
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
```

## Usage
RUN `docker-compose up -d` 

RUN `docker-compose scale web=3`

than RUN `docker-compose ps` you can see there are 4 containers running.
<table>
<tr>
<th>Name</th>
<th>Command</th>
<th>State</th>
<th>Ports</th>
</tr>
<tr>
<td>loadbalanceexample_lb_1</td>
<td>/sbin/tini -- dockercloud- ...</td>
<td>Up</td>
<td>0.0.0.0:80->80/tcp</td>
</tr>
<tr>
<td>loadbalanceexample_web_1</td>
<td>node app.js</td>
<td>Up</td>
<td>0.0.0.0:32769->3000/tcp</td>
</tr>
<tr>
<td>loadbalanceexample_web_2</td>
<td>node app.js</td>
<td>Up</td>
<td>0.0.0.0:32770->3000/tcp</td>
</tr>
<tr>
<td>loadbalanceexample_web_3</td>
<td>node app.js</td>
<td>Up</td>
<td>0.0.0.0:32771->3000/tcp</td>
</tr>
</table>

Visit [localhost](http://localhost) and refresh many times, you can find the hostnames are different.

## Mechanism
In the below table, you can see that the three ports of web containers are 32769, 32770 and 32771. And the ports maps to 3000. That because we don't specify the port of web in docker-compose.yml. Therefore, docker assigns random ports to web containers. And  
/etc/var/docker.sock:/etc/var/docker.sock is added in the file(.sock file is Unix domain socket file), so HAProxy can communicate to the api of docker host. Then it can know how many linked containers and their hostnames, so it can create the config by itself. You can use below command to see the generated config.

`docker exec loadbalanceexample_lb_1 cat haproxy.cfg`

You can RUN `docker-compose scale web=<number>` to scale up or down the web containers, the PAProxy could update its config by itself, which is very convenient and smart. 

You might consider that the load balance only occur on a single machine, so in next article, I will show you how to scale and load balance on docker swarm on multiple machines.