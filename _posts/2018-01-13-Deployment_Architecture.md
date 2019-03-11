---
layout: post
title: CI practices with TeamCity and AWS
description: How we do CI in SWARMNYC, using TeamCity and AWS Application Pipeline.
tags: 
    - Continuous Integration
    - AWS Application Pipeline
    - TeamCity
    - Best Practices
    - DevOps
---
<!-- Cumstomzie image style: having border, horizontal center, white background -->
<style>
    img {
        border: solid 1px lightgrey;
        background-color: white;
        display: block;
        margin-left: auto;
        margin-right: auto;
    }
</style>

# Goal

Here at <a href="https://www.swarmnyc.com" target="_blank">SWARM</a>, our engineering team & DevOps team have agreed on the following goals for deploying applications into the wild.

* Automatic

Deployment should happen automatically. Creating and publishing packages are for the dark ages!

* Reproducible

Production environment should be the same as the development environment. Issues in production should be easy to reproduce in development.

* Elastic

Easy to scale up or down services based upon demand.

* Smooth

Zero-downtime while scaling or upgrading the service.

* Traceable

Logging & monitoring should be in place to watch for issues

# Workflow

Our workflow needs to account for several folks to coordinate in pushing out a build.

1. Developers commit code / update scripts to git. We use [gitflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow) to keep track commits for our dev / qa / production environments.

2. Our CI Platform of choice [TeamCity](https://www.jetbrains.com/teamcity/) automatically kicks in to create a build, test it and then deploy it to QA. It then notifies our PM & QA teams to verify the latest build. Once approved

3. We use a combination of TeamCity & AWS Application Pipeline to generate builds for the production environments.

![image alt text](image_0.png)

# Deploying backend apps with AWS Application Pipeline

When we try to deploy an application in AWS, let’s say [Ludlow2](http://ludlow.io), we should set up an application pipeline first. 

# ![image alt text](image_1.png)

A typical pipeline includes:

* One [Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html)

* Several [Target Groups](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html) (each for one branch: dev, qa, prod)

    * Each Target Group is used to route requests to one or more registered targets by a Load Balancer listener rule. 

* Several [ECS services](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html) (each for one branch: dev, qa, prod)

    * ECS service is a specified number of instances of a task definition you can run and maintain simultaneously in an Amazon ECS cluster. 

* Several [ECR repositories](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_Console_Repositories.html) (each for one branch: dev, qa, prod)

    * ECR is a managed AWS Docker registry service which supports private Docker repositories. You can use the Docker CLI to author and manage images.

* One [EC2 instance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/concepts.html)

    * An EC2 instance provides scalable computing capacity in the Amazon Web Services (AWS) cloud. 

## Prerequisite

* AWS account

* Site domain name for your application, e.g.

    * *.ludlow.io

    * qa.ludlow.io

    * prod.ludlow.io

* Site certificate

## Application Pipeline Setup

See the [detail operations](/2018/01/16/SWARM-DevOps-on-AWS.html#application-pipeline-setup-overview).

# Deploying frontend apps with AWS WebApp Pipeline

![image alt text](image_2.png)

We use [Angular 4+](https://angular.io/) to build our web app frontend, which basically is a static web page. By deploying the frontend page to AWS CloudFront, a CDN service, we can make  faster and more reliable deliveries of  the web app content to users across the globe.

## WebApp Pipeline Setup

See the [detail operations](/2018/01/16/SWARM-DevOps-on-AWS.html#webapp-pipeline-setup).

# Continuous Integration (CI) with TeamCity and AWS

For CI, we set up a standalone TeamCity server instance as a docker container for each client and deploy it to AWS. The build agent is also a docker container that serves as an image for multiple on-demand build agents running on AWS.

While, the official build agent from jetbrains is great, most of our projects also need support for Node.js and AWS tools. So we created our own docker image for the TeamCity build agent where we bundled in the Node.js development environment and installed AWS CLI tools

These are available on [GitHub](https://github.com/swarmnyc/teamcity-buildagent-docker-images) or on [Docker Hub](https://hub.docker.com/u/swarmnyc/).

In this flow we focus on building backend API application server building as another docker image.

![image alt text](image_3.png)

## Unit Testing

TeamCity is great for running unit test, which can nicely show the test result report and code coverage report. TeamCity supports different test frameworks. We pick [Karma ](http://karma-runner.github.io/1.0/intro/installation.html)as our test framework, which can be used for backend apps (Node.js) as well as front-end (Angular) apps. Also, Karma is TeamCity friendly by using its [TeamCity plugin ](http://karma-runner.github.io/1.0/plus/teamcity.html).

Karma has a plugin [karma-coverage-istanbul-reporter](https://github.com/mattlewis92/karma-coverage-istanbul-reporter) to generate coverage report, which is a html page, zipped them as an Artifact: coverage.zip. TeamCity could recognize it and create a Code Coverage tab for you automatically.

![image alt text](image_4.png)

*In an Angular project, Start a test by command: **ng test --code-coverage*

TeamCity could generate a nice statistic report for you based on historical unit test results.

![image alt text](image_5.png)

## Build

1. Building Docker Image by Docker Build Runner

![image alt text](image_6.png)

2. Pushing Docker image to ECR, then deploy to ECS

![image alt text](image_7.png)

These 2 Build Steps should be the same while building a docker image. The differences are coming from the Parameters.

![image alt text](image_8.png)

## Deployment

We are using [ECS Deploy](https://github.com/fabfuel/ecs-deploy) to do the deployment, which is triggered by the last command in Build phase:

*ecs *deploy* %ECS_CLUSTER_NAME% %ECS_SERVICE_NAME% %AWS_REGION% %ECS_DEPLOY_OPTIONS%*

This tells [Amazon ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html) to duplicate the current Task Definition and cause the Service to redeploy all running tasks. 

The new task will be started while the old one is still running. When the new task successfully registers to the Target Group, the old one will stop and unregister(draining) from the Target Group. From the User’s perspective, the application(Ludlow2) is upgraded without any downtime.

### TODO

* All the env files are commit to GitHub, convenience yet insecurity. Instead of being put into version control, they should be generated in TeamCity Build phase.

## Integration with IDE

If you are using IntelliJ-based IDEs, e.g. WebStorm, you can [install the TeamCity Plugin](https://blog.jetbrains.com/teamcity/2017/10/teamcity-integration-with-intellij-based-ides/), which take advantage of all the features provided by TeamCity as a continuous integration server without leaving the context of the IDE. 

The coolest function is **Remote Run**, which is similar as git commit. Instead of committing to your github repository, it just commit to the TeamCity server and do a CI cycle based on your local change.

![image alt text](image_9.png) ⇒ ![image alt text](image_10.png) ⇒ ![image alt text](image_11.png)

# Logging 

We are using [CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/WhatIsCloudWatchLogs.html) for logging. 

When setting up the ECS Task Definitions in [Application Pipeline](#heading=h.c8ckfm2wqham), we already redirect application output to CloudWatch by **awslogs**. In this way, the application doesn’t need to change anything and the console.log messages will go to CloudWatch.

![image alt text](image_12.png)

In case you want to control the log flow, e.g. log to different stream based on the session, you could use AWS Log API, e.g. [winston-cloudwatch](https://github.com/lazywithclass/winston-cloudwatch).

# Alerts

CloudWatch has Alarms, you can create one based on build-in or your own customized Metrics. We will show below how to send an email to develop team when there is a error happened in production server.

1. Create a Metric Filter based on a Log Group

![image alt text](image_13.png)

2. Create Alarm based on the Metric

![image alt text](image_14.png)

3. Define how to trigger alert.

![image alt text](image_15.png)

